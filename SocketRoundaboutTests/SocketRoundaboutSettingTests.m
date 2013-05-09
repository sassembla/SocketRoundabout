//
//  SocketRoundaboutSetingTests.h
//  SocketRoundabout
//
//  Created by sassembla on 2013/05/03.
//  Copyright (c) 2013年 KISSAKI Inc,. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "AppDelegate.h"

#import "KSMessenger.h"

#define TEST_MASTER (@"TEST_MASTER_2013/05/03 21:23:10")
#define TEST_SETTINGFILE    (@"./setting.txt")
#define TEST_EMPTY_SETTINGFILE    (@"./empty.txt")
#define TEST_NOTEXIST_SETTINGFILE    (@"./notexist.txt")
#define TEST_SETTINGFILE_WITH_OPTION    (@"./settingWithOpt.txt")
#define TEST_SETTINGFILE_WITH_OPTION_MULTI  (@"./settingWithOpt_multi.txt")//未使用、まだ複数のオプションには対応していない。

#define TEST_BASE_SETTINGFILE   (@".")

#define TEST_MASTER_TIMELIMIT   (5)

#define GLOBAL_NNOTIF   (@"/Users/sassembla/Desktop/nnotifd/tool/nnotif")
#define TEST_NNOTIFD_ID_MANUAL  (@"NNOTIFD_IDENTITY")

#define TEST_NNOTIF_LOG (@"./nnotif.log")

#define TEST_NNOTIFD_IDENTITY   (@"NNOTIFD_IDENTITY")
#define TEST_NNOTIFD_OUTPUT (@"./s.log")//this points user's home via nnotifd

#define TEST_SR_DISTNOTIF   (@"testNotif")

#define CURRENT_SR_CL   (@"./app/SocketRoundabout")

@interface TestDistNotificationSender3 : NSObject @end
@implementation TestDistNotificationSender3

- (void) sendNotification:(NSString * )identity withMessage:(NSString * )message withKey:(NSString * )key {
    
    NSArray * clArray = @[@"-v", @"-o", TEST_NNOTIF_LOG, @"-t", identity, @"-k", key, @"-i", message];
    
    NSTask * task1 = [[NSTask alloc] init];
    [task1 setLaunchPath:GLOBAL_NNOTIF];
    [task1 setArguments:clArray];
    [task1 launch];
    [task1 waitUntilExit];
}
@end

@interface SocketRoundaboutSetingTests : SenTestCase {
    KSMessenger * messenger;
    AppDelegate * delegate;
    
    NSMutableArray * m_proceedLogArray;
    NSMutableArray * m_noLoadLogArray;
    NSMutableArray * m_errorLogArray;
}

@end

@implementation SocketRoundaboutSetingTests
- (void) setUp {
    [super setUp];
    messenger = [[KSMessenger alloc]initWithBodyID:self withSelector:@selector(receiver:) withName:TEST_MASTER];
    
    m_proceedLogArray = [[NSMutableArray alloc]init];
    m_noLoadLogArray = [[NSMutableArray alloc]init];
    m_errorLogArray = [[NSMutableArray alloc]init];
}

- (void) tearDown {
    
    [m_proceedLogArray removeAllObjects];
    [m_noLoadLogArray removeAllObjects];
    [m_errorLogArray removeAllObjects];
    
    if (delegate) [delegate exit];
    
    [messenger closeConnection];
    [super tearDown];
}

- (void) receiver:(NSNotification * )notif {
    NSDictionary * dict = [messenger tagValueDictionaryFromNotification:notif];
    switch ([messenger execFrom:SOCKETROUNDABOUT_MASTER viaNotification:notif]) {
            
        case SOCKETROUNDABOUT_MASTER_NO_LOADSETTING:{
            NSLog(@"hereComes");
            [m_noLoadLogArray addObject:dict];
            break;
        }
        case SOCKETROUNDABOUT_MASTER_LOADSETTING_OVERED:{
            NSAssert(dict[@"loadedPath"], @"loadedPath required");
            [m_proceedLogArray addObject:dict[@"loadedPath"]];
            break;
        }
        case SOCKETROUNDABOUT_MASTER_LOADSETTING_ERROR:{
            [m_errorLogArray addObject:dict];
            break;
        }
        default:
            break;
    }
}

/**
 設定ファイルを読み込んで、その通りの通信が実現できる状態になったら、信号を返す
 */
- (void) testInputSetting {
    int currentSettingSize = 1;
    
    NSDictionary * dict = @{KEY_SETTING:TEST_SETTINGFILE,
                            KEY_MASTER:TEST_MASTER};
    delegate = [[AppDelegate alloc]initAppDelegateWithParam:dict];
    NSString * settingSource = [delegate defaultSettingSource];
    [delegate loadSetting:settingSource];
    
    //各行の内容を順にセットアップして、完了したら通知
    
    int i = 0;
    while ([m_proceedLogArray count] < currentSettingSize) {
        [[NSRunLoop currentRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
        i++;
        if (TEST_MASTER_TIMELIMIT < i) {
            STFail(@"too late");
            break;
        }
    }

    //突破できればOK
}

/**
 空の設定ファイルを読み込んで、信号を返す
 */
- (void) testInputEmptySetting {
    int currentSettingSize = 1;
    
    NSDictionary * dict = @{KEY_SETTING:TEST_EMPTY_SETTINGFILE,
                            KEY_MASTER:TEST_MASTER};
    delegate = [[AppDelegate alloc]initAppDelegateWithParam:dict];
    NSString * settingSource = [delegate defaultSettingSource];
    [delegate loadSetting:settingSource];
    
    //各行の内容を順にセットアップして、完了したら通知
    
    int i = 0;
    while ([m_noLoadLogArray count] < currentSettingSize) {
        [[NSRunLoop currentRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
        i++;
        if (TEST_MASTER_TIMELIMIT < i) {
            STFail(@"too late");
            break;
        }
    }
    
    //突破できればOK
}

/**
 存在しない設定ファイルを読み込んで、エラーを返す
 */
- (void) testInputNotExistSetting {
    NSDictionary * dict = @{KEY_SETTING:TEST_NOTEXIST_SETTINGFILE,
                            KEY_MASTER:TEST_MASTER};
    delegate = [[AppDelegate alloc]initAppDelegateWithParam:dict];
    NSString * settingSource = [delegate defaultSettingSource];
    NSLog(@"settingSource %@", settingSource);
    [delegate loadSetting:settingSource];
    
    //突破できればOK
    
    int i = 0;
//    while ([m_proceedLogArray count] < currentSettingSize) {
//        [[NSRunLoop currentRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
//        i++;
//        if (TEST_MASTER_TIMELIMIT < i) {
//            STFail(@"too late");
//            break;
//        }
//    }

}

/**
 特に-sキー指定が無ければ、手元のファイルをロードする。
 この場合、DEFAULT_SETTINGS指定のものと同様の結果になる。
 */
- (void) testAutoLoadSetting {
    int currentSettingSize = 1;
    NSDictionary * dict = @{KEY_MASTER:TEST_MASTER,
                            PRIVATEKEY_BASEPATH:TEST_BASE_SETTINGFILE};
    delegate = [[AppDelegate alloc]initAppDelegateWithParam:dict];
    NSString * settingSource = [delegate defaultSettingSource];
    [delegate loadSetting:settingSource];
    
    //各行の内容を順にセットアップして、完了したら通知
    
    int i = 0;
    while ([m_noLoadLogArray count] < currentSettingSize) {
        [[NSRunLoop currentRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
        i++;
        if (TEST_MASTER_TIMELIMIT < i) {
            STFail(@"too late");
            break;
        }
    }

}

/**
 コマンドラインからの起動
 */
- (void) testLoadSettingAsCommandLine {
    NSArray * clArray = @[@"-s", TEST_SETTINGFILE];
    
    NSTask * task1 = [[NSTask alloc] init];
    [task1 setLaunchPath:CURRENT_SR_CL];
    [task1 setArguments:clArray];
    [task1 launch];
    
    //セッティングを読み込んで起動しているはず。UIは無い。
    
    [task1 terminate];
}


//////////////設定を行った後の挙動



/**
 設定後の挙動
 */
- (void) testRunAfterSetting {
    int currentSettingSize = 1;
    
    NSDictionary * dict = @{KEY_SETTING:TEST_SETTINGFILE,
                            KEY_MASTER:TEST_MASTER};
    delegate = [[AppDelegate alloc]initAppDelegateWithParam:dict];
    NSString * setting = [delegate defaultSettingSource];
    [delegate loadSetting:setting];
    
    //各行の内容を順にセットアップして、完了したら通知
    
    int i = 0;
    while ([m_proceedLogArray count] < currentSettingSize) {
        [[NSRunLoop currentRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
        i++;
        if (TEST_MASTER_TIMELIMIT < i) {
            STFail(@"too late");
            break;
        }
    }
    
    //通信が構築されてる筈なので、nnotifでの入力を行う
    //stdinを、SocketRoundaboutのNotifに向ける
    //nnotif -> nnotifd -> SocketRoundabout:DistNotif -> SocketRoundabout:ws -> STとか
    NSArray * execsArray = @[@"/usr/local/bin/gradle", @"-b", @"/Users/sassembla/Desktop/HelloWorld/build.gradle", @"build", @"-i", @"|", GLOBAL_NNOTIF, @"-t", TEST_SR_DISTNOTIF, @"-o", TEST_NNOTIFD_OUTPUT, @"--ignorebl"];
    
    //notifでexecuteを送り込む
    NSArray * execArray = @[@"nn@", @"-e",[self jsonizedString:execsArray]];
    NSString * exec = [execArray componentsJoinedByString:@" "];
    
    TestDistNotificationSender3 * nnotifSender = [[TestDistNotificationSender3 alloc]init];
    [nnotifSender sendNotification:TEST_NNOTIFD_ID_MANUAL withMessage:exec withKey:@"NN_DEFAULT_ROUTE"];
    
    
    //単純に待つ
    i = 0;
    while (i < TEST_MASTER_TIMELIMIT) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
        i++;
       
        if (TEST_MASTER_TIMELIMIT + TEST_MASTER_TIMELIMIT < i) {
            STFail(@"too long wait");
            break;
        }
    }

}

- (NSString * ) jsonizedString:(NSArray * )jsonSourceArray {
    
    //add before-" and after-"
    NSMutableArray * addHeadAndTailQuote = [[NSMutableArray alloc]init];
    for (NSString * item in jsonSourceArray) {
        [addHeadAndTailQuote addObject:[NSString stringWithFormat:@"\"%@\"", item]];
    }
    
    //concat with ,
    NSString * concatted = [addHeadAndTailQuote componentsJoinedByString:@","];
    return [[NSString alloc] initWithFormat:@"%@[%@]", @"nn:", concatted];
}

/**
 オプションパラメータがあった場合
 */
- (void) testSettingWithOption {
    int currentSettingSize = 1;
    
    NSDictionary * dict = @{KEY_SETTING:TEST_SETTINGFILE_WITH_OPTION,
                            KEY_MASTER:TEST_MASTER};
    delegate = [[AppDelegate alloc]initAppDelegateWithParam:dict];
    NSString * settingSource = [delegate defaultSettingSource];
    [delegate loadSetting:settingSource];
    
    //各行の内容を順にセットアップして、完了したら通知
    
    int i = 0;
    while ([m_proceedLogArray count] < currentSettingSize) {
        [[NSRunLoop currentRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
        i++;
        if (TEST_MASTER_TIMELIMIT < i) {
            STFail(@"too late");
            break;
        }
    }
    
    //突破できればOK    
}

@end
