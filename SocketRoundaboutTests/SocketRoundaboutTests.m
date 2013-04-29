//
//  SocketRoundaboutTests.h
//  SocketRoundaboutTests
//
//  Created by sassembla on 2013/04/17.
//  Copyright (c) 2013年 KISSAKI Inc,. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "KSMessenger.h"

#import "RoundaboutController.h"


#define TEST_MASTER (@"TEST_MASTER_2013/04/28 22:26:38")

#define TEST_WEBSOCKETSERVER   (@"ws://127.0.0.1:8823")
#define TEST_NOTIFICATIONSERVER  (@"notif://2013/04/29 17:52:05")

#define TEST_CONNECTIONIDENTITY_1 (@"roundaboutTest1")
#define TEST_CONNECTIONIDENTITY_2   (@"roundaboutTest2")

#define TEST_TIMELIMIT  (1)
#define TEST_REFLECTIVE_MESSAGE (@"ss@broadcastMessage:{\"message\":\"MESSAGE_2013/04/29 17:34:39\"}")

#define NNOTIF  (@"./nnotif")//pwd = project-folder path.
#define TEST_DISTNOTIF_MESSAGE  (@"TEST_DISTNOTIF_MESSAGE_2013/04/29 17:57:57")

@interface TestDistNotificationSender2 : NSObject @end
@implementation TestDistNotificationSender2

- (void) sendNotification:(NSString * )identity withMessage:(NSString * )message withKey:(NSString * )key {
    
    NSArray * clArray = @[@"-t", identity, @"-k", key, @"-i", message];
    
    NSTask * task1 = [[NSTask alloc] init];
    [task1 setLaunchPath:NNOTIF];
    [task1 setArguments:clArray];
    [task1 launch];
    [task1 waitUntilExit];
}
@end

@interface SocketRoundaboutTests : SenTestCase {
    KSMessenger * messenger;
    RoundaboutController * rCont;
    NSMutableArray * m_connectionIdArray;
}

@end


@implementation SocketRoundaboutTests

- (void) setUp {
    messenger = [[KSMessenger alloc] initWithBodyID:self withSelector:@selector(receiver:) withName:TEST_MASTER];
    rCont = [[RoundaboutController alloc]initWithMaster:[messenger myNameAndMID]];
    m_connectionIdArray = [[NSMutableArray alloc]init];
}

- (void) tearDown {
    [messenger closeConnection];
    [rCont closeAllConnections];
    [rCont exit];
    [m_connectionIdArray removeAllObjects];
}


- (void) receiver:(NSNotification * )notif {
    NSDictionary * dict = [messenger tagValueDictionaryFromNotification:notif];
    switch ([messenger execFrom:KS_ROUNDABOUTCONT viaNotification:notif]) {
        case KS_ROUNDABOUTCONT_CONNECT_ESTABLISHED:{
            NSAssert(dict[@"connectionId"], @"connectionId required");
            [m_connectionIdArray addObject:dict[@"connectionId"]];
            break;
        }
        default:
            break;
    }
}

/**
 WebSocket 1,2が接続完了後に相互接続
 */
- (void) testConnectWebSocket_1And2 {
    //1
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_1],
     [messenger tag:@"connectionType" val:[NSNumber numberWithInt:KS_ROUNDABOUTCONT_CONNECTION_TYPE_WEBSOCKET]],
     nil];

    //2
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_2],
     [messenger tag:@"connectionType" val:[NSNumber numberWithInt:KS_ROUNDABOUTCONT_CONNECTION_TYPE_WEBSOCKET]],
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
    
    //connect
    [rCont outFrom:TEST_CONNECTIONIDENTITY_1 into:TEST_CONNECTIONIDENTITY_2];
    
    //設定を取得
    NSArray * out1 = [rCont outputsOf:TEST_CONNECTIONIDENTITY_1];
    STAssertTrue([out1 count] == 1, @"not match, %d", [out1 count]);

    NSArray * in2 = [rCont inputsOf:TEST_CONNECTIONIDENTITY_2];
    STAssertTrue([in2 count] == 1, @"not match, %d", [in2 count]);
}

/**
 WebSocket 1,2が接続完了後、broadcastを開始(どこかで反射をやめる機構を用意しないとアレだが、今回は無限反射を回数で落とす。)
 コイツ自体にemit能力は無いので、WSServerへと、「接続している全Clientへとメッセージ送付」を利用する。
 */
- (void) testConnectWebSocket_1And2_Then_SendData {
    //1
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_1],
     [messenger tag:@"connectionType" val:[NSNumber numberWithInt:KS_ROUNDABOUTCONT_CONNECTION_TYPE_WEBSOCKET]],
     nil];
    
    //2
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_2],
     [messenger tag:@"connectionType" val:[NSNumber numberWithInt:KS_ROUNDABOUTCONT_CONNECTION_TYPE_WEBSOCKET]],
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
    
    //connect
    [rCont outFrom:TEST_CONNECTIONIDENTITY_1 into:TEST_CONNECTIONIDENTITY_2];
    
    /*
     ServerへとC1からbroadcastを実行。
     C1 -> Server -> C1,C2
     1,2ともに受け取るが、1のみout、2のみinを持っているので、
     ->C1 -> (SocketRoundabout) -> C2 となるようにする。
     */
    
    //debug用の直接送信
    [rCont directInput:TEST_CONNECTIONIDENTITY_1 message:TEST_REFLECTIVE_MESSAGE];
    
    while ([rCont transitOutputCount:TEST_CONNECTIONIDENTITY_1] == 0) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
    //C1 -> C2へと通達が行き、サーバへとinputを行ってしまうため、C1が一通受け取った時点で、待つのをやめる。
    
    //C1にメッセージが届いている。内容は、TEST_REFLECTIVE_MESSAGEのmessageの中身。
    STAssertTrue([rCont transitOutputCount:TEST_CONNECTIONIDENTITY_1] == 1, @"not match, %d", [rCont transitOutputCount:TEST_CONNECTIONIDENTITY_1]);
    
    //C2にメッセージが、C1から届く
    STAssertTrue([rCont transitInputCount:TEST_CONNECTIONIDENTITY_2] == 1, @"not match, %d", [rCont transitInputCount:TEST_CONNECTIONIDENTITY_2]);
    
    //Serverへとメッセージが届く(この部分はSRWebSocketが担保)
}

/**
 DistNotificationとWebSocketの接続
 */
- (void) testConnectionWebSocket_1And2_Reserve {
    //1
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_NOTIFICATIONSERVER],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_1],
     [messenger tag:@"connectionType" val:[NSNumber numberWithInt:KS_ROUNDABOUTCONT_CONNECTION_TYPE_NOTIFICATION]],
     nil];
    
    //2
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_2],
     [messenger tag:@"connectionType" val:[NSNumber numberWithInt:KS_ROUNDABOUTCONT_CONNECTION_TYPE_WEBSOCKET]],
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
    
    //connect
    [rCont outFrom:TEST_CONNECTIONIDENTITY_1 into:TEST_CONNECTIONIDENTITY_2];
    
    /*
     C1へと別プロセスからDistNotifivationを実行。
     other -> C1 -> (SocketRoundabout) -> C2 となるようにする。
     */
    
    //debug用の直接送信
    //sender
    TestDistNotificationSender2 * sender = [[TestDistNotificationSender2 alloc]init];
    
    
    //送付
    [sender sendNotification:TEST_NOTIFICATIONSERVER withMessage:TEST_DISTNOTIF_MESSAGE withKey:@"message"];
    
    while ([rCont transitOutputCount:TEST_CONNECTIONIDENTITY_1] == 0) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }

    
    //C1にメッセージが届いている。内容は、TEST_DISTNOTIF_MESSAGE
    STAssertTrue([rCont transitOutputCount:TEST_CONNECTIONIDENTITY_1] == 1, @"not match, %d", [rCont transitOutputCount:TEST_CONNECTIONIDENTITY_1]);
    
    //C2にメッセージが、C1から届く
    STAssertTrue([rCont transitInputCount:TEST_CONNECTIONIDENTITY_2] == 1, @"not match, %d", [rCont transitInputCount:TEST_CONNECTIONIDENTITY_2]);
    
    //Serverへとメッセージが届く(この部分はSRWebSocketが担保)
}

@end
