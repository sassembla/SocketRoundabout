//
//  SocketRoundaboutTests_singleConnection.h
//  SocketRoundabout
//
//  Created by sassembla on 2013/04/23.
//  Copyright (c) 2013年 KISSAKI Inc,. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "KSMessenger.h"
#import "RoundaboutController.h"


#define TEST_MASTER (@"TEST_MASTER")


#define TEST_WEBSOCKETSERVER   (@"ws://127.0.0.1:8823")
#define TEST_CONNECTIONIDENTITY_1 (@"roundaboutTest1")
#define TEST_CONNECTIONIDENTITY_2   (@"roundaboutTest2")


@interface SocketRoundaboutTests_singleConnection : SenTestCase {
    KSMessenger * messenger;
    RoundaboutController * roundaboutCont;
    NSMutableArray * m_connectionIdArray;
}

@end


@implementation SocketRoundaboutTests_singleConnection

- (void)setUp {
    NSLog(@"setUp");
    messenger = [[KSMessenger alloc]initWithBodyID:self withSelector:@selector(receiver:) withName:TEST_MASTER];
    roundaboutCont = [[RoundaboutController alloc]initWithMaster:[messenger myNameAndMID]];
    
    m_connectionIdArray = [[NSMutableArray alloc]init];
}

- (void)tearDown {
    [messenger closeConnection];
    [roundaboutCont exit];
    
    [m_connectionIdArray removeAllObjects];
    
    NSLog(@"tearDown");    
}

- (void) receiver:(NSNotification * )notif {
    NSLog(@"test reveived");
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



- (void) testConnect {
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_1],
     nil];
    
    
    int i = 0;
    while ([m_connectionIdArray count] < 1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
        i++;
        if (10 < i) {
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
     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_1],
     nil];
    
    
    int i = 0;
    while ([m_connectionIdArray count] < 1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
        i++;
        if (10 < i) {
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
     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_1],
     nil];
    
    
    int i = 0;
    while ([m_connectionIdArray count] < 1) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
        i++;
        if (10 < i) {
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
     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_1],
     nil];
    
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_2],
     nil];
    
    int i = 0;
    while ([m_connectionIdArray count] < 2) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
        i++;
        if (10 < i) {
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
     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_1],
     nil];
    
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_2],
     nil];
    
    int i = 0;
    while ([m_connectionIdArray count] < 2) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
        i++;
        if (10 < i) {
            STFail(@"too long wait");
            break;
        }
    }
    
    [roundaboutCont closeConnection:TEST_CONNECTIONIDENTITY_1];
    
    STAssertTrue([[roundaboutCont connections] count] == 1, @"not match, %d", [[roundaboutCont connections] count]);
}







/**
 Clientとして特定の振る舞いを行う
 */
- (void) testInputClientId {
    
}













@end
