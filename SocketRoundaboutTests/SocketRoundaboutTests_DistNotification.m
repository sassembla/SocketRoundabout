//
//  SocketRoundaboutTests_DistNotification.h
//  SocketRoundabout
//
//  Created by sassembla on 2013/04/25.
//  Copyright (c) 2013年 KISSAKI Inc,. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "KSMessenger.h"
#import "RoundaboutController.h"


#define TEST_MASTER (@"TEST_MASTER")


#define TEST_NOTIFICATION_IDENTITY  (@"nsdist://TEST_NOTIFICATION_IDENTITY_2013/04/25 0:16:43")
#define TEST_CONNECTIONIDENTITY_1 (@"roundaboutTest1")
#define TEST_CONNECTIONIDENTITY_2   (@"roundaboutTest2")

#define TEST_TIMELIMIT  (1)

#define TEST_KEY    (@"TEST_KEY_2013/05/08 21:13:50")


#define NNOTIF  (@"./tool/nnotif")//pwd = project-folder path.


@interface TestDistNotificationSender : NSObject @end
@implementation TestDistNotificationSender

- (void) sendNotification:(NSString * )identity withMessage:(NSString * )message withKey:(NSString * )key {
    
    NSArray * clArray = @[@"-t", identity, @"-k", key, @"-i", message];
    
    NSTask * task1 = [[NSTask alloc] init];
    [task1 setLaunchPath:NNOTIF];
    [task1 setArguments:clArray];
    [task1 launch];
    [task1 waitUntilExit];
}

@end


@interface SocketRoundaboutTests_DistNotification : SenTestCase {
    KSMessenger * messenger;
    RoundaboutController * roundaboutCont;
    NSMutableArray * m_connectionIdArray;
}

@end



@implementation SocketRoundaboutTests_DistNotification

- (void)setUp {
    
    NSLog(@"setUp");
    [super setUp];
    messenger = [[KSMessenger alloc]initWithBodyID:self withSelector:@selector(receiver:) withName:TEST_MASTER];
    roundaboutCont = [[RoundaboutController alloc]initWithMaster:[messenger myNameAndMID]];
    
    m_connectionIdArray = [[NSMutableArray alloc]init];
}

- (void)tearDown {
    [messenger closeConnection];
    [roundaboutCont exit];
    
    [m_connectionIdArray removeAllObjects];
    
    [super tearDown];
    NSLog(@"tearDown");
}

- (void) receiver:(NSNotification * )notif {
    
    NSDictionary * dict = [messenger tagValueDictionaryFromNotification:notif];
    
    switch ([messenger execFrom:KS_ROUNDABOUTCONT viaNotification:notif]) {
        case KS_ROUNDABOUTCONT_CONNECT_ESTABLISHED:{
            STAssertNotNil([dict valueForKey:@"connectionId"], @"connectionId required");
            [m_connectionIdArray addObject:dict[@"connectionId"]];
            break;
        }
            
        default:
            break;
    }
}

//////////////////////////////////////
// DistributedNotification
//////////////////////////////////////

- (void) testConnect {
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_NOTIFICATION_IDENTITY],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_1],
     nil];
    
    
    int i = 0;
    while ([m_connectionIdArray count] < 1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
        i++;
        if (TEST_TIMELIMIT < i) {
            STFail(@"too long wait");
            break;
        }
    }
    
    //接続できているconnectionが一つある
    STAssertTrue([[roundaboutCont connections] count] == 1, @"not match, %d", [[roundaboutCont connections] count]);
}

/**
 一度開いたConnectionを閉じる
 */
- (void) testCloseAll {
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_NOTIFICATION_IDENTITY],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_1],
     nil];
    
    
    int i = 0;
    while ([m_connectionIdArray count] < 1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
        i++;
        if (TEST_TIMELIMIT < i) {
            STFail(@"too long wait");
            break;
        }
    }
    
    [roundaboutCont closeAllConnections];
    
    //接続中のConnectionは存在しない
    STAssertTrue([[roundaboutCont connections] count] == 0, @"not match, %d", [[roundaboutCont connections] count]);
}

/**
 特定のConnectionを閉じる
 */
- (void) testCloseSpecific {
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_NOTIFICATION_IDENTITY],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_1],
     nil];
    
    
    int i = 0;
    while ([m_connectionIdArray count] < 1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
        i++;
        if (TEST_TIMELIMIT < i) {
            STFail(@"too long wait");
            break;
        }
    }
    
    [roundaboutCont closeConnection:TEST_CONNECTIONIDENTITY_1];
    
    STAssertTrue([[roundaboutCont connections] count] == 0, @"not match, %d", [[roundaboutCont connections] count]);
}


/**
 複数のConnectionを開く
 */
- (void) testOpenMulti {
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_NOTIFICATION_IDENTITY],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_1],
     nil];
    
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_NOTIFICATION_IDENTITY],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_2],
     nil];
    
    int i = 0;
    while ([m_connectionIdArray count] < 2) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
        i++;
        if (TEST_TIMELIMIT < i) {
            STFail(@"too long wait");
            break;
        }
    }
    
    STAssertTrue([[roundaboutCont connections] count] == 2, @"not match, %d", [[roundaboutCont connections] count]);
}


/**
 特定のConnectionを閉じて、他のConnectionが影響を受けない
 */
- (void) testCloseSpecificAndRest1 {
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_NOTIFICATION_IDENTITY],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_1],
     nil];
    
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_NOTIFICATION_IDENTITY],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_2],
     nil];
    
    int i = 0;
    while ([m_connectionIdArray count] < 2) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
        i++;
        if (TEST_TIMELIMIT < i) {
            STFail(@"too long wait");
            break;
        }
    }
    
    [roundaboutCont closeConnection:TEST_CONNECTIONIDENTITY_1];
    
    STAssertTrue([[roundaboutCont connections] count] == 1, @"not match, %d", [[roundaboutCont connections] count]);
}

/**
 入力を行い、receiveを得る
 */
- (void) testGetReceived {
    
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_NOTIFICATION_IDENTITY],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_1],
     nil];
    
    int i = 0;
    while ([m_connectionIdArray count] < 1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
        i++;
        if (TEST_TIMELIMIT < i) {
            STFail(@"too long wait");
            break;
        }
    }
    
    //sender
    TestDistNotificationSender * sender = [[TestDistNotificationSender alloc]init];
    
    //送付
    [sender sendNotification:TEST_NOTIFICATION_IDENTITY withMessage:@"testMessage" withKey:@"message"];

    //一件取得できる
    STAssertTrue([roundaboutCont roundaboutMessageCount] == 1, @"not match, %d", [roundaboutCont roundaboutMessageCount]);
}

- (void) testGetReceived_Twice {
    
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_NOTIFICATION_IDENTITY],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_1],
     nil];
    
    int i = 0;
    while ([m_connectionIdArray count] < 1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
        i++;
        if (TEST_TIMELIMIT < i) {
            STFail(@"too long wait");
            break;
        }
    }
    
    //sender
    TestDistNotificationSender * sender = [[TestDistNotificationSender alloc]init];
    
    //送付
    [sender sendNotification:TEST_NOTIFICATION_IDENTITY withMessage:@"testMessage" withKey:@"message"];
    [sender sendNotification:TEST_NOTIFICATION_IDENTITY withMessage:@"testMessage2" withKey:@"message"];
    
    //2件取得できる
    STAssertTrue([roundaboutCont roundaboutMessageCount] == 2, @"not match, %d", [roundaboutCont roundaboutMessageCount]);
}



/**
 出力時のキーを調整する
 */
- (void) testOptionKey_OutputKey {
    
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_NOTIFICATION_IDENTITY],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_1],
     [messenger tag:@"connectionOption" val:@{@"outputKey":TEST_KEY}],//出力時のuserinfo内のキーをTEST_KEYの値のものに変化させる。
     nil];
    
    int i = 0;
    while ([m_connectionIdArray count] < 1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
        i++;
        if (TEST_TIMELIMIT < i) {
            STFail(@"too long wait");
            break;
        }
    }
    
    //sender
    TestDistNotificationSender * sender = [[TestDistNotificationSender alloc]init];
    
    //送付
    [sender sendNotification:TEST_NOTIFICATION_IDENTITY withMessage:@"testMessage" withKey:@"message"];
    
    //1件取得できる
    STAssertTrue([roundaboutCont roundaboutMessageCount] == 1, @"not match, %d", [roundaboutCont roundaboutMessageCount]);
}



@end



