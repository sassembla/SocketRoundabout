//
//  SocketRoundaboutTests.h
//  SocketRoundaboutTests
//
//  Created by sassembla on 2013/04/17.
//  Copyright (c) 2013年 KISSAKI Inc,. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "KSMessenger.h"
#import "WebSocketController.h"

#define TEST_MASTER (@"TEST_MASTER")
#define TEST_SLAVE (@"TEST_SLAVE")

#define ADDRESS_A   (@"ws://127.0.0.1:8823")
#define ADDRESS_B   (@"ws://127.0.0.1:8824")


@interface SocketRoundaboutTests : SenTestCase {
    KSMessenger * messenger;
    WebSocketController * wsCont;
    NSMutableArray * m_connectionIdArray;
    NSMutableArray * m_receivedMessageArray;
}

@end


@implementation SocketRoundaboutTests

- (void)setUp
{
    [super setUp];
    
    messenger = [[KSMessenger alloc]initWithBodyID:self withSelector:@selector(receiver:) withName:TEST_MASTER];
    wsCont = [[WebSocketController alloc]initWebSocketControllerWithMasterName:TEST_MASTER];
    m_connectionIdArray = [[NSMutableArray alloc]init];
    m_receivedMessageArray = [[NSMutableArray alloc]init];
}

- (void)tearDown
{
    [messenger closeConnection];
    [wsCont closeMessengerConnection];
    [m_connectionIdArray removeAllObjects];
    [m_receivedMessageArray removeAllObjects];
    
    [super tearDown];
}


- (void) receiver:(NSNotification * )notif {
    NSDictionary * dict = [messenger tagValueDictionaryFromNotification:notif];
    
    switch ([messenger execFrom:KS_WEBSOCKETCONTROL viaNotification:notif]) {
        case KS_WEBSOCKETCONTROL_OPENED:{
            NSAssert([dict valueForKey:@"connectionId"], @"connectionId required");
            NSString * appendableId = [[NSString alloc]initWithString:[dict valueForKey:@"connectionId"]];
            [m_connectionIdArray addObject:appendableId];
            break;
        }
        case KS_WEBSOCKETCONTROL_RECEIVEDMESSAGE:{
            NSAssert([dict valueForKey:@"connectionId"], @"connectionId required");
            NSAssert([dict valueForKey:@"message"], @"message required");
            
            NSString * message = [[NSString alloc]initWithString:[dict valueForKey:@"message"]];
            [m_receivedMessageArray addObject:message];
            break;
        }
            
        default:
            break;
    }
}


- (void) testConnect8823 {
    NSString * TEST_CONNECTION_A = @"2013/04/18 16:14:50";
    [messenger call:KS_WEBSOCKETCONTROL withExec:KS_WEBSOCKETCONTROL_CONNECTTOA,
     [messenger tag:@"targetURL" val:ADDRESS_A],
     [messenger tag:@"connectionId" val:TEST_CONNECTION_A],
     nil];
    
    //confirm open
    while ([m_connectionIdArray count] == 0) {
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
	}
    STAssertEqualObjects([m_connectionIdArray objectAtIndex:0], TEST_CONNECTION_A, @"not match");
    
    //confirm close
    
}


- (void) testConnect8824 {
    NSString * TEST_CONNECTION_B = @"2013/04/18 16:15:05";
    [messenger call:KS_WEBSOCKETCONTROL withExec:KS_WEBSOCKETCONTROL_CONNECTTOB,
     [messenger tag:@"targetURL" val:ADDRESS_B],
     [messenger tag:@"connectionId" val:TEST_CONNECTION_B],
     nil];
    
    //confirm open
    while ([m_connectionIdArray count] == 0) {
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
	}
    STAssertEqualObjects([m_connectionIdArray objectAtIndex:0], TEST_CONNECTION_B, @"not match");
    
    //confirm close = autodisconnect
}

- (void) testConnectToAandB {
    NSString * TEST_CONNECTION_A = @"2013/04/18 16:15:21";
    NSString * TEST_CONNECTION_B = @"2013/04/18 16:15:36";
    
    [messenger call:KS_WEBSOCKETCONTROL withExec:KS_WEBSOCKETCONTROL_CONNECTTOA,
     [messenger tag:@"targetURL" val:ADDRESS_A],
     [messenger tag:@"connectionId" val:TEST_CONNECTION_A],
     nil];
    
    [messenger call:KS_WEBSOCKETCONTROL withExec:KS_WEBSOCKETCONTROL_CONNECTTOB,
     [messenger tag:@"targetURL" val:ADDRESS_B],
     [messenger tag:@"connectionId" val:TEST_CONNECTION_B],
     nil];
    
    while ([m_connectionIdArray count] != 2) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
    
    STAssertTrue([m_connectionIdArray containsObject:TEST_CONNECTION_A], @"not match");
    STAssertTrue([m_connectionIdArray containsObject:TEST_CONNECTION_B], @"not match");    
    
}


/**
 A,B両方にメッセージを送付して、それぞれが返信される
 */
- (void) testBroadcastReceived {
    NSString * TEST_CONNECTION_A = @"2013/04/18 16:15:55";
    NSString * TEST_CONNECTION_B = @"2013/04/18 16:16:05";
    [messenger call:KS_WEBSOCKETCONTROL withExec:KS_WEBSOCKETCONTROL_CONNECTTOA,
     [messenger tag:@"targetURL" val:ADDRESS_A],
     [messenger tag:@"connectionId" val:TEST_CONNECTION_A],
     nil];
    
    [messenger call:KS_WEBSOCKETCONTROL withExec:KS_WEBSOCKETCONTROL_CONNECTTOB,
     [messenger tag:@"targetURL" val:ADDRESS_B],
     [messenger tag:@"connectionId" val:TEST_CONNECTION_B],
     nil];
    
    //wait for connect
    while ([m_connectionIdArray count] != 2) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
    
    [messenger call:KS_WEBSOCKETCONTROL withExec:KS_WEBSOCKETCONTROL_BROADCASTMESSAGE,
     [messenger tag:@"connectionIds" val: @[TEST_CONNECTION_A, TEST_CONNECTION_B]],
     [messenger tag:@"message" val:@"ss@broadcastMessage:{\"message\":\"hereComes\"}"],
     nil];
    
    //wait received
    while ([m_receivedMessageArray count] != 2) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
    
    STAssertTrue([m_receivedMessageArray count] == 2, @"not yet 2");
    
    STAssertEqualObjects([m_receivedMessageArray objectAtIndex:0], @"hereComes", @"not match");
    STAssertEqualObjects([m_receivedMessageArray objectAtIndex:1], @"hereComes", @"not match");
}

/**
 Aからメッセージを受け取り、Bに伝播する
 */
- (void) testTransmitReceived {
    NSString * TEST_CONNECTION_A = @"2013/04/18 16:16:16";
    NSString * TEST_CONNECTION_B = @"2013/04/18 16:16:32";
    [messenger call:KS_WEBSOCKETCONTROL withExec:KS_WEBSOCKETCONTROL_CONNECTTOA,
     [messenger tag:@"targetURL" val:ADDRESS_A],
     [messenger tag:@"connectionId" val:TEST_CONNECTION_A],
     nil];
    
    [messenger call:KS_WEBSOCKETCONTROL withExec:KS_WEBSOCKETCONTROL_CONNECTTOB,
     [messenger tag:@"targetURL" val:ADDRESS_B],
     [messenger tag:@"connectionId" val:TEST_CONNECTION_B],
     nil];
    
    //wait for connect
    while ([m_connectionIdArray count] != 2) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
    
    
    [messenger call:KS_WEBSOCKETCONTROL withExec:KS_WEBSOCKETCONTROL_SET_TRANSMITMODE,
     [messenger tag:@"isTransmit" val:[NSNumber numberWithBool:true]],
     nil];
    
    
    //to A
    [messenger call:KS_WEBSOCKETCONTROL withExec:KS_WEBSOCKETCONTROL_SENDMESSAGE,
     [messenger tag:@"connectionId" val:TEST_CONNECTION_A],
     [messenger tag:@"message" val:@"ss@broadcastMessage:{\"message\":\"hereComesFromClient\"}"],
     nil];

    
    //message returned
    
    //message transmitted from A to B
    
    //wait received from B
    while ([m_receivedMessageArray count] != 2) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
    
    NSLog(@"over");
    
}





@end
