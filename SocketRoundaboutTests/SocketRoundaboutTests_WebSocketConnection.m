//
//  SocketRoundaboutTests_WebSocketConnection.h
//  SocketRoundabout
//
//  Created by sassembla on 2013/04/23.
//  Copyright (c) 2013年 KISSAKI Inc,. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "KSMessenger.h"
#import "RoundaboutController.h"


#define TEST_MASTER (@"TEST_MASTER")


#define TEST_WEBSOCKETSERVER_AS_CLIENT  (@"ws://127.0.0.1:8823")
#define TEST_WEBSOCKETSERVER_AS_SERVER  (@"ws://127.0.0.1:8824")
#define TEST_WEBSOCKETSERVER_AS_SERVER_0  (@"ws://127.0.0.1:8825")
#define TEST_WEBSOCKETSERVER_AS_SERVER_1  (@"ws://127.0.0.1:8826")
#define TEST_WEBSOCKETSERVER_AS_SERVER_2  (@"ws://127.0.0.1:8827")
#define TEST_WEBSOCKETSERVER_AS_SERVER_3  (@"ws://127.0.0.1:8828")
#define TEST_WEBSOCKETSERVER_AS_SERVER_4  (@"ws://127.0.0.1:8829")
#define TEST_WEBSOCKETSERVER_AS_SERVER_5  (@"ws://127.0.0.1:8830")
#define TEST_WEBSOCKETSERVER_AS_SERVER_6  (@"ws://127.0.0.1:8831")
#define TEST_WEBSOCKETSERVER_AS_SERVER_7  (@"ws://127.0.0.1:8832")

#define TEST_WEBSOCKETSERVER_AS_CLIENT_TOSERVER (@"ws://127.0.0.1:8831")


#define TEST_CONNECTIONIDENTITY_1 (@"roundaboutTest1")
#define TEST_CONNECTIONIDENTITY_2   (@"roundaboutTest2")

#define TEST_TIMELIMIT  (5)
@interface SocketRoundaboutTests_WebSocketConnection : SenTestCase {
    KSMessenger * messenger;
    RoundaboutController * roundaboutCont;
    NSMutableArray * m_connectionIdArray;
}

@end


@implementation SocketRoundaboutTests_WebSocketConnection

- (void)setUp {
    [super setUp];
    NSLog(@"setUp");
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
// WebSocket client
//////////////////////////////////////

- (void) testConnectAsClient {
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER_AS_CLIENT],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_1],
     [messenger tag:@"connectionType" val:[NSNumber numberWithInt:KS_ROUNDABOUTCONT_CONNECTION_TYPE_WEBSOCKET]],
     [messenger tag:@"connectionOption" val:@{@"type":@"client"}],
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
    
    NSArray * key = [[[roundaboutCont connections] allKeys] objectAtIndex:0];
    
    NSNumber * type = [roundaboutCont connections][key][@"connectionType"];
    STAssertTrue([type intValue] == KS_ROUNDABOUTCONT_CONNECTION_TYPE_WEBSOCKET, @"not match, %@", type);
}

/**
 一度開いたConnectionを閉じる
 */
- (void) testCloseAllAsClient {
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER_AS_CLIENT],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_1],
     [messenger tag:@"connectionType" val:[NSNumber numberWithInt:KS_ROUNDABOUTCONT_CONNECTION_TYPE_WEBSOCKET]],
     [messenger tag:@"connectionOption" val:@{@"type":@"client"}],
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
- (void) testCloseSpecificAsClient {
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER_AS_CLIENT],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_1],
     [messenger tag:@"connectionType" val:[NSNumber numberWithInt:KS_ROUNDABOUTCONT_CONNECTION_TYPE_WEBSOCKET]],
     [messenger tag:@"connectionOption" val:@{@"type":@"client"}],
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
- (void) testOpenMultiAsClient {
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER_AS_CLIENT],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_1],
     [messenger tag:@"connectionType" val:[NSNumber numberWithInt:KS_ROUNDABOUTCONT_CONNECTION_TYPE_WEBSOCKET]],
     [messenger tag:@"connectionOption" val:@{@"type":@"client"}],
     nil];
    
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER_AS_CLIENT],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_2],
     [messenger tag:@"connectionType" val:[NSNumber numberWithInt:KS_ROUNDABOUTCONT_CONNECTION_TYPE_WEBSOCKET]],
     [messenger tag:@"connectionOption" val:@{@"type":@"client"}],
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
- (void) testCloseSpecificAndRest1AsClient {
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER_AS_CLIENT],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_1],
     [messenger tag:@"connectionType" val:[NSNumber numberWithInt:KS_ROUNDABOUTCONT_CONNECTION_TYPE_WEBSOCKET]],
     [messenger tag:@"connectionOption" val:@{@"type":@"client"}],
     nil];
    
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER_AS_CLIENT],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_2],
     [messenger tag:@"connectionType" val:[NSNumber numberWithInt:KS_ROUNDABOUTCONT_CONNECTION_TYPE_WEBSOCKET]],
     [messenger tag:@"connectionOption" val:@{@"type":@"client"}],
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


//////////////////////////////////////
// WebSocket server
//////////////////////////////////////
/**
 サーバとして立ち上げる。
 クライアントすべてへとoutbound-out、
 クライアントすべてからoutbound-in
 */
- (void) testConnect {
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER_AS_SERVER],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_1],
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
    
    //接続できているconnectionが一つある
    STAssertTrue([[roundaboutCont connections] count] == 1, @"not match, %d", [[roundaboutCont connections] count]);
    
    NSArray * key = [[[roundaboutCont connections] allKeys] objectAtIndex:0];
    
    NSNumber * type = [roundaboutCont connections][key][@"connectionType"];
    STAssertTrue([type intValue] == KS_ROUNDABOUTCONT_CONNECTION_TYPE_WEBSOCKET, @"not match, %@", type);
}

/**
 一度開いたConnectionを閉じる
 */
- (void) testCloseAll {
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER_AS_SERVER_0],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_1],
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
    
    [roundaboutCont closeAllConnections];
    
    //接続中のConnectionは存在しない
    STAssertTrue([[roundaboutCont connections] count] == 0, @"not match, %d", [[roundaboutCont connections] count]);
}

/**
 特定のConnectionを閉じる
 */
- (void) testCloseSpecific {
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER_AS_SERVER_1],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_1],
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
    
    [roundaboutCont closeConnection:TEST_CONNECTIONIDENTITY_1];
    
    STAssertTrue([[roundaboutCont connections] count] == 0, @"not match, %d", [[roundaboutCont connections] count]);
}


/**
 複数のConnectionを開く
 */
- (void) testOpenMulti {
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER_AS_SERVER_2],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_1],
     [messenger tag:@"connectionType" val:[NSNumber numberWithInt:KS_ROUNDABOUTCONT_CONNECTION_TYPE_WEBSOCKET]],
     nil];
    
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER_AS_SERVER_3],
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
    
    STAssertTrue([[roundaboutCont connections] count] == 2, @"not match, %d", [[roundaboutCont connections] count]);
}


/**
 特定のConnectionを閉じて、他のConnectionが影響を受けない
 */
- (void) testCloseSpecificAndRest1 {
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER_AS_SERVER_4],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_1],
     [messenger tag:@"connectionType" val:[NSNumber numberWithInt:KS_ROUNDABOUTCONT_CONNECTION_TYPE_WEBSOCKET]],
     nil];
    
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER_AS_SERVER_5],
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
    
    [roundaboutCont closeConnection:TEST_CONNECTIONIDENTITY_1];
    
    STAssertTrue([[roundaboutCont connections] count] == 1, @"not match, %d", [[roundaboutCont connections] count]);
}

/**
 通信が可能かどうか、動作させてみる
 */
- (void) testServerEmit {
    //server
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER_AS_SERVER_6],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_1],
     [messenger tag:@"connectionType" val:[NSNumber numberWithInt:KS_ROUNDABOUTCONT_CONNECTION_TYPE_WEBSOCKET]],
     nil];
    
    //client
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER_AS_CLIENT_TOSERVER],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_2],
     [messenger tag:@"connectionType" val:[NSNumber numberWithInt:KS_ROUNDABOUTCONT_CONNECTION_TYPE_WEBSOCKET]],
     [messenger tag:@"connectionOption" val:@{@"type":@"client"}],
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
    
    //この時点で、接続が確立している筈。
    NSLog(@"hereComes");
}

/**
 別記法でのサーバセットアップ
 */
- (void) testServerEmitWithAnotherTokenStyle {
    //server
    [messenger call:KS_ROUNDABOUTCONT withExec:KS_ROUNDABOUTCONT_CONNECT,
     [messenger tag:@"connectionTargetAddr" val:TEST_WEBSOCKETSERVER_AS_SERVER_7],
     [messenger tag:@"connectionId" val:TEST_CONNECTIONIDENTITY_1],
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
}
@end
