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

#define TEST_BASE_SETTINGFILE   (@".")

#define TEST_MASTER_TIMELIMIT   (5)

@interface SocketRoundaboutSetingTests : SenTestCase {
    KSMessenger * messenger;
    AppDelegate * delegate;
    NSMutableArray * m_proceedLogArray;
    NSMutableArray * m_errorLogArray;
}

@end

@implementation SocketRoundaboutSetingTests
- (void) setUp {
    messenger = [[KSMessenger alloc]initWithBodyID:self withSelector:@selector(receiver:) withName:TEST_MASTER];
    m_proceedLogArray = [[NSMutableArray alloc]init];
    m_errorLogArray = [[NSMutableArray alloc]init];
}

- (void) tearDown {
    [delegate exit];
    [messenger closeConnection];
}

- (void) receiver:(NSNotification * )notif {
    NSDictionary * dict = [messenger tagValueDictionaryFromNotification:notif];
    switch ([messenger execFrom:SOCKETROUNDABOUT_MASTER viaNotification:notif]) {
            
        case SOCKETROUNDABOUT_MASTER_LOADSETTING_OVERED:{
            [m_proceedLogArray addObject:dict];
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
    [delegate loadSetting];
    
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
    [delegate loadSetting];
    
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

///**
// 存在しない設定ファイルを読み込んで、エラーを返す
// */
//- (void) testInputNotExistSetting {
//    int currentSettingSize = 1;
//    
//    NSDictionary * dict = @{KEY_SETTING:TEST_NOTEXIST_SETTINGFILE,
//                            KEY_MASTER:TEST_MASTER};
//    delegate = [[AppDelegate alloc]initAppDelegateWithParam:dict];
//    [delegate loadSetting];
//    
//    
//    int i = 0;
//    while ([m_errorLogArray count] < currentSettingSize) {
//        [[NSRunLoop currentRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
//        i++;
//        if (TEST_MASTER_TIMELIMIT < i) {
//            STFail(@"too late");
//            break;
//        }
//    }
//    
//    //突破できればOK
//}


/**
 特に-sキー指定が無ければ、手元のファイルをロードする。
 この場合、DEFAULT_SETTINGS指定のものと同様の結果になる。
 */
- (void) testAutoLoadSetting {
    NSDictionary * dict = @{KEY_MASTER:TEST_MASTER,
                            PRIVATEKEY_BASEPATH:TEST_BASE_SETTINGFILE};
    delegate = [[AppDelegate alloc]initAppDelegateWithParam:dict];
    [delegate loadSetting];
    
    //各行の内容を順にセットアップして、完了したら通知
}

@end
