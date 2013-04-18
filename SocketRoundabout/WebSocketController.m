//
//  WebSocketController.m
//  
//
//  Created by 井上 徹 on 2013/02/14.
//  Copyright (c) 2013年 KISSAKI.inc. All rights reserved.
//

#import "WebSocketController.h"



@implementation WebSocketController {
    SRWebSocket *_webSocketA;
    SRWebSocket *_webSocketB;
}

bool m_transmit = false;

- (id)initWebSocketControllerWithMasterName:(NSString * )masterName {
    if (self = [super init]) {
        messenger = [[KSMessenger alloc]initWithBodyID:self withSelector:@selector(receiver:) withName:KS_WEBSOCKETCONTROL];
        [messenger connectParent:masterName];
        
        connectionDict = [[NSMutableDictionary alloc]init];
    }
    
    return self;
}

- (void) receiver:(NSNotification * )notif {
    NSDictionary * dict = [messenger tagValueDictionaryFromNotification:notif];
    
    switch ([messenger execFrom:[messenger myParentName] viaNotification:notif]) {

        case KS_WEBSOCKETCONTROL_CONNECTTOA:{
            NSAssert([dict valueForKey:@"targetURL"], @"targetURL required");
            NSAssert([dict valueForKey:@"connectionId"], @"connectionId required");
            
            [self connectToA:[dict valueForKey:@"targetURL"] withIdentity:[dict valueForKey:@"connectionId"]];
            break;
        }
            
        case KS_WEBSOCKETCONTROL_CONNECTTOB:{
            NSAssert([dict valueForKey:@"targetURL"], @"targetURL required");
            NSAssert([dict valueForKey:@"connectionId"], @"connectionId required");
            
            [self connectToB:[dict valueForKey:@"targetURL"] withIdentity:[dict valueForKey:@"connectionId"]];
            break;
        }
        case KS_WEBSOCKETCONTROL_SENDMESSAGE:{
            NSAssert([dict valueForKey:@"connectionId"], @"connectionId required");
            NSAssert([dict valueForKey:@"message"], @"message required");
            
            [self sendMessageToWebSocket:[dict valueForKey:@"connectionId"] message:[dict valueForKey:@"message"]];
            break;
        }
        case KS_WEBSOCKETCONTROL_BROADCASTMESSAGE:{
            NSAssert([dict valueForKey:@"connectionIds"], @"connectionIds required");
            NSAssert([dict valueForKey:@"message"], @"message required");
            
            NSArray * connectionIds = [dict valueForKey:@"connectionIds"];
            for (NSString * connectionId in connectionIds) {
                [self sendMessageToWebSocket:connectionId message:[dict valueForKey:@"message"]];
            }
            
            break;
        }
            
        case KS_WEBSOCKETCONTROL_SET_TRANSMITMODE:{
            NSAssert([dict valueForKey:@"isTransmit"], @"isTransmit required");
            m_transmit = [[dict valueForKey:@"isTransmit"] boolValue];
            break;
        }
            
        
        
            
        default:
            break;
    }
    
    switch ([messenger execFrom:[messenger myName] viaNotification:notif]) {
        case KS_WEBSOCKETCONTROL_SENDMESSAGE:{
            NSAssert([dict valueForKey:@"connectionId"], @"connectionId required");
            NSAssert([dict valueForKey:@"message"], @"message required");
            
            [self sendMessageToWebSocket:[dict valueForKey:@"connectionId"] message:[dict valueForKey:@"message"]];
            break;
        }
            
        default:
            break;
    }
}

/**
 connect to WebSocket Server
 */

- (void) connectToA:(NSString * )connectTargetAddress withIdentity:(NSString * )connectionId {
    _webSocketA.delegate = nil;
    [_webSocketA close];
    
    _webSocketA = [[SRWebSocket alloc] initWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:connectTargetAddress]]];
    
    //store connectionId - generatedWebSocketInstance
    [connectionDict setValue:_webSocketA forKey:connectionId];
    
    _webSocketA.delegate = self;
    [_webSocketA open];
    
}

- (void) connectToB:(NSString * )connectTargetAddress withIdentity:(NSString * )connectionId {
    _webSocketB.delegate = nil;
    [_webSocketB close];
    
    _webSocketB = [[SRWebSocket alloc] initWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:connectTargetAddress]]];
    
    //store connectionId - generatedWebSocketInstance
    [connectionDict setValue:_webSocketB forKey:connectionId];
    
    _webSocketB.delegate = self;
    [_webSocketB open];
    
}



/**
 send data to WebSocket Server
 */
- (void) sendMessageToWebSocket:(NSString * )identity message:(NSString * )message {
    SRWebSocket * ws = [connectionDict valueForKey:identity];
    [ws send:message];
}


- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    NSString * connectionId = [[connectionDict allKeysForObject:webSocket] objectAtIndex:0];
    
    [messenger callParent:KS_WEBSOCKETCONTROL_OPENED,
     [messenger tag:@"connectionId" val:connectionId],
     nil];
}

- (void)webSocket:(SRWebSocket * )webSocket didFailWithError:(NSError * )error {
    NSLog(@"error   %@", error);
//    NSString * connectionId = [[connectionDict allKeysForObject:webSocket] objectAtIndex:0];
    
//    [messenger callParent:KS_WEBSOCKETCONTROL_FAILWITHERROR,
//     [messenger tag:@"error" val:error],
//     [messenger tag:@"connectionId" val:connectionId],
//     nil];
//    
//    //delete from dict
//    [connectionDict removeObjectForKey:connectionId];
//    
//    NSLog(@":( Websocket Failed With Error %@", error);
//    _webSocket = nil;
}

- (void)webSocket:(SRWebSocket * )webSocket didReceiveMessage:(id)message {
    NSString * connectionId = [[connectionDict allKeysForObject:webSocket] objectAtIndex:0];

    [messenger callParent:KS_WEBSOCKETCONTROL_RECEIVEDMESSAGE,
     [messenger tag:@"connectionId" val:connectionId],
     [messenger tag:@"message" val:message],
     nil];
    
    if (m_transmit) {
        NSString * anotherConnectionId;
        for (NSString * key in [connectionDict keyEnumerator]) {
            if ([key isEqualToString:connectionId]) continue;
            anotherConnectionId = key;
        }
        
        
        [messenger callMyself:KS_WEBSOCKETCONTROL_SENDMESSAGE,
         [messenger tag:@"connectionId" val:anotherConnectionId],
         [messenger tag:@"message" val:@"ss@broadcastMessage:{\"message\":\"hereComes2\"}"],
         nil];
    }
}

- (void)webSocket:(SRWebSocket * )webSocket didCloseWithCode:(NSInteger)code reason:(NSString * )reason wasClean:(BOOL)wasClean {
    NSString * connectionId = [[connectionDict allKeysForObject:webSocket] objectAtIndex:0];
    NSLog(@"closed  %ld, %@, %@", (long)code, reason, connectionId);
    
//
//    [messenger callParent:KS_WEBSOCKETCONTROL_CLOSED,
//     [messenger tag:@"code" val:[NSNumber numberWithInt:code]],
//     [messenger tag:@"reason" val:reason],
//     [messenger tag:@"connectionId" val:connectionId],
//     nil];
//    
//    //delete from dict
//    [connectionDict removeObjectForKey:connectionId];
//
//    _webSocket = nil;
}


- (void) closeMessengerConnection {
    [messenger closeConnection];
    
    for (SRWebSocket * socket in [connectionDict allValues]) {
        socket.delegate = nil;
    }
    
    [connectionDict removeAllObjects];
}


@end
