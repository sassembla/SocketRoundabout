//
//  AppDelegate.m
//  SocketRoundabout
//
//  Created by sassembla on 2013/04/17.
//  Copyright (c) 2013年 KISSAKI Inc,. All rights reserved.
//

#import "AppDelegate.h"
#import "KSMessenger.h"
#import "RoundaboutController.h"

#import "MainWindow.h"

@implementation AppDelegate {
    KSMessenger * messenger;
    
    RoundaboutController * rCont;
    
    NSString * m_defaultSettingSource;
    int m_lock;
    NSMutableArray * m_lines;
    int m_loaded;
}

void uncaughtExceptionHandler(NSException * exception) {
    NSLog(@"CRASH: %@", exception);
    NSLog(@"Stack Trace: %@", [exception callStackSymbols]);
}

- (BOOL)application:(NSApplication * )theApplication openFile:(NSString * )filename {
    [self log:[NSString stringWithFormat:@"openFile filename %@", filename]];
    m_defaultSettingSource = [[NSString alloc]initWithString:filename];
    return YES;
}

- (id) initAppDelegateWithParam:(NSDictionary * )argsDict {
    
    if (self = [super init]) {
        messenger = [[KSMessenger alloc]initWithBodyID:self withSelector:@selector(receiver:) withName:SOCKETROUNDABOUT_MASTER];
        if (argsDict[KEY_MASTER]) [messenger connectParent:argsDict[KEY_MASTER]];
        
        //ファイルから開く場合、
        if (m_defaultSettingSource) {NSLog(@"opening:%@", m_defaultSettingSource);} else {
            if (argsDict[KEY_SETTING]) {
                m_defaultSettingSource = [[NSString alloc]initWithString:argsDict[KEY_SETTING]];
            } else {
                NSAssert(argsDict[PRIVATEKEY_BASEPATH], @"basePath get error");
                
                //現在のディレクトリはどこか、起動引数からわかるはず
                m_defaultSettingSource = [[NSString alloc]initWithFormat:@"%@/%@",argsDict[PRIVATEKEY_BASEPATH], DEFAULT_SETTINGS];
            }
        }
        
        rCont = [[RoundaboutController alloc]initWithMaster:[messenger myNameAndMID]];
    }
    
    return self;
}

/**
 load implemented-settings when launch
 */
- (void)applicationDidFinishLaunching:(NSNotification * )aNotification {
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    [self loadSetting:m_defaultSettingSource];
}

- (NSString * ) defaultSettingSource {
    return m_defaultSettingSource;
}

/**
 ファイルパスから設定を読み出す。
 特になんのガードも無いため、一つのファイルだけにするのが好ましい。
 */
- (void) loadSetting:(NSString * )source {
    NSAssert(source, @"source is nil.");
        
    NSFileHandle * handle = [NSFileHandle fileHandleForReadingAtPath:source];
    
    if (handle) {} else {
        if ([messenger hasParent]) [messenger callParent:SOCKETROUNDABOUT_MASTER_LOADSETTING_ERROR, nil];
        [self log:[NSString stringWithFormat:@"%@%@",@"cannot load file:%@", source]];
        return;
    }
    
    NSData * data = [handle readDataToEndOfFile];
    NSString * string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    NSMutableArray * array = [[NSMutableArray alloc]initWithArray:[string componentsSeparatedByString:@"\n"]];
    
    //remove emptyLine and comment, not expect codehead line.
    m_lines = [[NSMutableArray alloc]init];
    
    NSArray * execList = @[CODEHEAD_ID, CODEHEAD_CONNECT, CODEHEAD_TRANS, CODEHEAD_EMIT, CODEHEAD_EMITFILE, MARK_NO_CODEHEAD];
    for (NSString * line in array) {
        for (NSString * expect in execList) {
            if ([line hasPrefix:expect]) [m_lines addObject:line];
        }
    }
    
    if (0 < [m_lines count]) {
        //linesに対して、上から順に動作を行う
        //ロードの開始、カウントの行を読み、実行する
        
        //初期化(ロードのための初期化なので、あとからでも出来る)
        m_lock = 0;
        m_loaded = 0;
        
        //別スレッドでロード
        [messenger callMyself:SOCKETROUNDABOUT_MASTER_LOADSETTING_LOAD,
         [messenger tag:@"lineNo" val:[NSNumber numberWithInt:m_lock]],
         [messenger withDelay:DEFINE_LOADING_INTERVAL],
         nil];
        
        [messenger callMyself:SOCKETROUNDABOUT_MASTER_LOADSETTING_LOADING, nil];
        
    } else {
        if ([messenger hasParent]) [messenger callParent:SOCKETROUNDABOUT_MASTER_NO_LOADSETTING, nil];
    }
}

- (void) receiver:(NSNotification * )notif {
    NSDictionary * dict = [messenger tagValueDictionaryFromNotification:notif];
    
    //自分自身
    /*
     マルチロードみたいなものを実現したい場合、ここを調整する必要があるが、
     そもそんな必要が無いので、シングルファイルのみが読める形になっている。
     */
    switch ([messenger execFrom:[messenger myName] viaNotification:notif]) {
            
        case SOCKETROUNDABOUT_MASTER_LOADSETTING_LOAD:{
            NSAssert(dict[@"lineNo"], @"lineNo required");
            [self log:[NSString stringWithFormat:@"%@%d", @"load start:line ", [dict[@"lineNo"] intValue]]];

            int lineNo = [dict[@"lineNo"] intValue];
            NSString * line = [[NSString alloc]initWithString:m_lines[lineNo]];
            [self load:line];
            break;
        }
        
        case SOCKETROUNDABOUT_MASTER_LOADSETTING_LOADING:{
            if (m_lock < m_loaded) {//完了通知が来たら抜けて次
                
                m_lock++;
                
                if (m_lock == [m_lines count]) {
                    //現在読み込んでいるファイルのlast lineに入った
                    if ([messenger hasParent]) {
                        NSString * loadedPath = m_defaultSettingSource;
                        [messenger callParent:SOCKETROUNDABOUT_MASTER_LOADSETTING_OVERED,
                         [messenger tag:@"loadedPath" val:loadedPath],
                         nil];
                    }

                    if ([[[messenger childrenDict] allValues] containsObject:SOCKETROUNDABOUT_MAINWINDOW]) {
                        [messenger call:SOCKETROUNDABOUT_MAINWINDOW withExec:SOCKETROUNDABOUT_MASTER_LOADSETTING_OVERED, nil];
                    }
                    [m_lines removeAllObjects];
                    return;//終了
                }
                
                [messenger callMyself:SOCKETROUNDABOUT_MASTER_LOADSETTING_LOAD,
                 [messenger tag:@"lineNo" val:[NSNumber numberWithInt:m_lock]],
                 nil];
            }
            
            [self log:[NSString stringWithFormat:@"loading line:%d %@", m_lock, m_lines[m_lock]]];
            
            [messenger callMyself:SOCKETROUNDABOUT_MASTER_LOADSETTING_LOADING,
             [messenger withDelay:DEFINE_LOADING_INTERVAL],
             nil];
            
            break;
        }
        
            
        default:
            break;
    }
    
    switch ([messenger execFrom:KS_ROUNDABOUTCONT viaNotification:notif]) {
        case KS_ROUNDABOUTCONT_CONNECT_ESTABLISHED:{
            NSAssert(dict[@"connectionId"], @"connectionId required");
            
            m_loaded++;
            break;
        }
        case KS_ROUNDABOUTCONT_SETCONNECT_OVER:{
            NSAssert(dict[@"from"], @"from required");
            NSAssert(dict[@"to"], @"to required");
            
            m_loaded++;
            break;
        }
        case KS_ROUNDABOUTCONT_SETTRANSFER_OVER:{
            NSAssert(dict[@"from"], @"from required");
            NSAssert(dict[@"to"], @"to required");
            NSAssert(dict[@"prefix"], @"prefix required");
            NSAssert(dict[@"postfix"], @"postfix required");
            
            m_loaded++;
            break;
        }
        case KS_ROUNDABOUTCONT_EMITMESSAGE_OVER:{
            NSAssert(dict[@"emitMessage"], @"emitMessage required");
            NSAssert(dict[@"to"], @"to required");
            
            m_loaded++;
            break;
        }
            
        default:
            break;
    }
    
    switch ([messenger execFrom:SOCKETROUNDABOUT_MAINWINDOW viaNotification:notif]) {
        case SOCKETROUNDABOUT_MAINWINDOW_INPUT_URI:{
            NSAssert(dict[@"uri"], @"uri required");
            [self loadSetting:dict[@"uri"]];
            
            break;
        }
            
        default:
            break;
    }
}

/**
 parse executable string
 */
- (void) load:(NSString * )exec {
    /*
     この3タイプを分解する
     id:TEST_CONNECTIONIDENTITY_1 type:KS_ROUNDABOUTCONT_CONNECTION_TYPE_NOTIFICATION destination:TEST_WEBSOCKETSERVER,
     connect:TEST_CONNECTIONIDENTITY_1 to:TEST_CONNECTIONIDENTITY_2,
     trans:TEST_CONNECTIONIDENTITY_3 to:TEST_CONNECTIONIDENTITY_4 prefix:TEST_PREFIX suffix:TEST_POSTFIX
     */
    NSArray * execsArray = [exec componentsSeparatedByString:CODE_DELIM];
    
    if ([execsArray[0] hasPrefix:CODEHEAD_ID]) {
        NSAssert1([execsArray[1] hasPrefix:CODE_TYPE], @"%@ required", CODE_TYPE);
        NSAssert1([execsArray[2] hasPrefix:CODE_DESTINATION], @"%@ required", CODE_DESTINATION);
        
        NSString * connectionId = [execsArray[0] componentsSeparatedByString:CODEHEAD_ID][1];
        NSString * connectionType = [execsArray[1] componentsSeparatedByString:CODE_TYPE][1];
        NSString * connectionTargetAddr = [execsArray[2] componentsSeparatedByString:CODE_DESTINATION][1];
        
        //optionが存在する場合がある。
        if (3 < [execsArray count]) {
            //要素が存在するので、分解する。
            NSArray * headAndKeyAndValues = [execsArray[3] componentsSeparatedByString:CODE_OPTION];
            NSArray * keyAndValues = [headAndKeyAndValues[1] componentsSeparatedByString:CODE_COMMA];

            NSMutableDictionary * optionDict = [[NSMutableDictionary alloc]init];
            
            for (NSString * keyAndValue in keyAndValues) {
                NSArray * keyAndValueArray = [keyAndValue componentsSeparatedByString:CODE_COLON];
                [optionDict setValue:keyAndValueArray[1] forKey:keyAndValueArray[0]];
            }
            
            [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
             [messenger tag:@"connectionTargetAddr" val:connectionTargetAddr],
             [messenger tag:@"connectionId" val:connectionId],
             [messenger tag:@"connectionType" val:connectionType],
             [messenger tag:@"connectionOption" val:optionDict],
             nil];
            
        } else {
            [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
             [messenger tag:@"connectionTargetAddr" val:connectionTargetAddr],
             [messenger tag:@"connectionId" val:connectionId],
             [messenger tag:@"connectionType" val:connectionType],
             nil];
        }
        
    } else if ([execsArray[0] hasPrefix:CODEHEAD_CONNECT]) {
        NSAssert1([execsArray[1] hasPrefix:CODE_TO], @"%@ required", CODE_TO);
        
        NSString * from = [execsArray[0] componentsSeparatedByString:CODEHEAD_CONNECT][1];
        NSString * to = [execsArray[1] componentsSeparatedByString:CODE_TO][1];
        
        [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_SETCONNECT,
         [messenger tag:@"from" val:from],
         [messenger tag:@"to" val:to],
         nil];
        
    } else if ([execsArray[0] hasPrefix:CODEHEAD_TRANS]) {
        NSAssert1([execsArray[1] hasPrefix:CODE_TO], @"%@ required", CODE_TO);
        NSAssert1([execsArray[2] hasPrefix:CODE_PREFIX], @"%@ required", CODE_PREFIX);
        NSAssert1([execsArray[3] hasPrefix:CODE_SUFFIX], @"%@ required", CODE_SUFFIX);
        
        NSString * from = [execsArray[0] componentsSeparatedByString:CODEHEAD_TRANS][1];
        NSString * to = [execsArray[1] componentsSeparatedByString:CODE_TO][1];
        NSString * prefix = [execsArray[2] componentsSeparatedByString:CODE_PREFIX][1];
        NSString * postfix = [execsArray[3] componentsSeparatedByString:CODE_SUFFIX][1];
        
        [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_SETTRANSFER,
         [messenger tag:@"from" val:from],
         [messenger tag:@"to" val:to],
         [messenger tag:@"prefix" val:prefix],
         [messenger tag:@"postfix" val:postfix],
         nil];
    } else if ([execsArray[0] hasPrefix:CODEHEAD_EMIT]) {
        NSAssert1([execsArray[1] hasPrefix:CODE_TO], @"%@ required", CODE_TO);
        
        NSString * emitMessage = [execsArray[0] componentsSeparatedByString:CODEHEAD_EMIT][1];
        NSString * to = [execsArray[1] componentsSeparatedByString:CODE_TO][1];
        
        [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_EMITMESSAGE,
         [messenger tag:@"emitMessage" val:emitMessage],
         [messenger tag:@"to" val:to],
         nil];
    } else if ([execsArray[0] hasPrefix:CODEHEAD_EMITFILE]) {
        NSAssert1([execsArray[1] hasPrefix:CODE_TO], @"%@ required", CODE_TO);
        
        NSString * filePath = [execsArray[0] componentsSeparatedByString:CODEHEAD_EMITFILE][1];
        
        //open file
        NSFileHandle * handle = [NSFileHandle fileHandleForReadingAtPath:filePath];
        
        if (handle) {} else {
            NSAssert(false, @"the emitfile-target is not exist:%@", filePath);
        }
        
        NSData * data = [handle readDataToEndOfFile];
        
        //load emitMessage from file.
        NSString * emitMessage = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        NSString * to = [execsArray[1] componentsSeparatedByString:CODE_TO][1];
        
        [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_EMITMESSAGE,
         [messenger tag:@"emitMessage" val:emitMessage],
         [messenger tag:@"to" val:to],
         nil];

    }

}

/**
 共通ログ出力
 */
- (void) log:(NSString * )log {
    NSLog(@"SocketRoudabout %@", log);
}

- (void) exit {
    [rCont exit];
    [messenger closeConnection];
}
@end
