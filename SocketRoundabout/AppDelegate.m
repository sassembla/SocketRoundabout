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

@implementation AppDelegate {
    KSMessenger * messenger;
    
    RoundaboutController * rCont;
    
    NSString * m_settingSource;
    int m_lock;
    NSMutableArray * m_lines;
    int m_loaded;
}

void uncaughtExceptionHandler(NSException *exception) {
    NSLog(@"CRASH: %@", exception);
    NSLog(@"Stack Trace: %@", [exception callStackSymbols]);
}


- (id) initAppDelegateWithParam:(NSDictionary * )argsDict {
    
    if (self = [super init]) {
        messenger = [[KSMessenger alloc]initWithBodyID:self withSelector:@selector(receiver:) withName:SOCKETROUNDABOUT_MASTER];
        if (argsDict[KEY_MASTER]) [messenger connectParent:argsDict[KEY_MASTER]];
        
        if (argsDict[KEY_SETTING]) {
            m_settingSource = [[NSString alloc]initWithString:argsDict[KEY_SETTING]];
        } else {
            NSAssert(argsDict[PRIVATEKEY_BASEPATH], @"basePath get error");
            
            //現在のディレクトリはどこか、起動引数からわかるはず
            m_settingSource = [[NSString alloc]initWithFormat:@"%@/%@",argsDict[PRIVATEKEY_BASEPATH], DEFAULT_SETTINGS];
        }
        
        rCont = [[RoundaboutController alloc]initWithMaster:[messenger myNameAndMID]];
    }
    
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    
    /*
     GUIがホシイけど、今すぐには必要ないし、使い続ける展望はまだ無いので、文字列入力がある前提、でいいか。
     だとすると、アプリじゃない方が都合がいい、、
     ので、initializerを用意しちゃって、そこから各設定を読もう。
     */
    
    [self loadSetting];
}

- (void) loadSetting {
    NSFileHandle * handle = [NSFileHandle fileHandleForReadingAtPath:m_settingSource];
    
    if (handle) {} else {
        if ([messenger hasParent]) [messenger callParent:SOCKETROUNDABOUT_MASTER_LOADSETTING_ERROR, nil];
        [self log:[NSString stringWithFormat:@"%@%@",@"cannot load file:%@", m_settingSource]];        
    }
    
    NSData * data = [handle readDataToEndOfFile];
    NSString * string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    NSMutableArray * array = [[NSMutableArray alloc]initWithArray:[string componentsSeparatedByString:@"\n"]];
    
    //remove empty and comment
    m_lines = [[NSMutableArray alloc]init];
    for (NSString * line in array) {
        if ([line hasPrefix:CODE_COMMENT]) {
            continue;
        } else if ([line isEqualToString:CODE_EMPTY]) {
            continue;
        }
        
        [m_lines addObject:line];
    }
    
    if (0 < [m_lines count]) {
        //linesに対して、上から順に動作を行う
        [messenger callMyself:SOCKETROUNDABOUT_MASTER_LOADSETTING_START, nil];
    } else {
        if ([messenger hasParent]) [messenger callParent:SOCKETROUNDABOUT_MASTER_LOADSETTING_OVERED, nil];
    }
}

- (void) receiver:(NSNotification * )notif {
    NSDictionary * dict = [messenger tagValueDictionaryFromNotification:notif];
    
    switch ([messenger execFrom:[messenger myName] viaNotification:notif]) {
        case SOCKETROUNDABOUT_MASTER_LOADSETTING_START:{
            //ロードの開始、カウントの行を読み、実行する

            //初期化(ロードのための初期化なので、あとからでも出来る)
            m_lock = 0;
            m_loaded = 0;
            
            //LOAD
            [messenger callMyself:SOCKETROUNDABOUT_MASTER_LOADSETTING_LOAD,
             [messenger tag:@"lineNo" val:[NSNumber numberWithInt:m_lock]],
             [messenger withDelay:0.0001],
             nil];
            
            [messenger callMyself:SOCKETROUNDABOUT_MASTER_LOADSETTING_LOADING, nil];
            break;
        }
            
        case SOCKETROUNDABOUT_MASTER_LOADSETTING_LOAD:{
            NSAssert(dict[@"lineNo"], @"lineNo required");
            [self log:[NSString stringWithFormat:@"%@%d", @"load start:line", [dict[@"lineNo"] intValue]]];

            int lineNo = [dict[@"lineNo"] intValue];
            [self load:m_lines[lineNo]];
            break;
        }
        
        case SOCKETROUNDABOUT_MASTER_LOADSETTING_LOADING:{
            if (m_lock < m_loaded) {//完了通知が来たら抜けて次
                
                m_lock++;
                
                if (m_lock == [m_lines count]) {
                    if ([messenger hasParent]) [messenger callParent:SOCKETROUNDABOUT_MASTER_LOADSETTING_OVERED, nil];
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
            m_loaded++;
            break;
        }
        case KS_ROUNDABOUTCONT_SETCONNECT_OVER:{
            m_loaded++;
            break;
        }
        case KS_ROUNDABOUTCONT_SETTRANSFER_OVER:{
            m_loaded++;
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
     trans:TEST_CONNECTIONIDENTITY_3 to:TEST_CONNECTIONIDENTITY_4 prefix:TEST_PREFIX postfix:TEST_POSTFIX
     */
    NSArray * execsArray = [exec componentsSeparatedByString:CODE_DELIM];
    
    if ([execsArray[0] hasPrefix:CODEHEAD_ID]) {
        NSAssert1([execsArray[1] hasPrefix:CODE_TYPE], @"%@ required", CODE_TYPE);
        NSAssert1([execsArray[2] hasPrefix:CODE_DESTINATION], @"%@ required", CODE_DESTINATION);
        
        NSString * connectionId = [execsArray[0] componentsSeparatedByString:CODEHEAD_ID][1];
        NSString * connectionType = [execsArray[1] componentsSeparatedByString:CODE_TYPE][1];
        NSString * connectionTargetAddr = [execsArray[2] componentsSeparatedByString:CODE_DESTINATION][1];
        
        [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
         [messenger tag:@"connectionTargetAddr" val:connectionTargetAddr],
         [messenger tag:@"connectionId" val:connectionId],
         [messenger tag:@"connectionType" val:connectionType],
         nil];
        
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
        NSAssert1([execsArray[3] hasPrefix:CODE_POSTFIX], @"%@ required", CODE_POSTFIX);
        
        NSString * from = [execsArray[0] componentsSeparatedByString:CODEHEAD_TRANS][1];
        NSString * to = [execsArray[1] componentsSeparatedByString:CODE_TO][1];
        NSString * prefix = [execsArray[2] componentsSeparatedByString:CODE_PREFIX][1];
        NSString * postfix = [execsArray[3] componentsSeparatedByString:CODE_POSTFIX][1];
        
        [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_SETTRANSFER,
         [messenger tag:@"from" val:from],
         [messenger tag:@"to" val:to],
         [messenger tag:@"prefix" val:prefix],
         [messenger tag:@"postfix" val:postfix],
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
