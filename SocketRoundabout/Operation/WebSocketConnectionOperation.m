//
//  WebSocketConnectionOperation.m
//  SocketRoundabout
//
//  Created by sassembla on 2013/04/23.
//  Copyright (c) 2013年 KISSAKI Inc,. All rights reserved.
//

/**
 WebSocketのConnection単位での保持を行うOperation
 
 */


#import "WebSocketConnectionOperation.h"
#import "KSMessenger.h"

/*
 m_operationId は、このインスタンスのidそのもの。このインスタンスと寿命をともにする。
 */
@implementation WebSocketConnectionOperation {
    NSString * m_operationId;
    KSMessenger * messenger;
    SRWebSocket * m_socket;
}

- (id) initWebSocketConnectionOperationWithMaster:(NSString * )masterNameAndId withConnectionTarget:(NSString * )targetAddr withConnectionIdentity:(NSString * )connectionIdentity {
    if (self = [super init]) {
        messenger = [[KSMessenger alloc]initWithBodyID:self withSelector:@selector(receiver:) withName:KS_WEBSOCKETCONNECTIONOPERATION];
        
        [messenger connectParent:masterNameAndId];
        
        m_operationId = [[NSString alloc]initWithString:connectionIdentity];
        m_socket = [[SRWebSocket alloc]initWithURL:[NSURL URLWithString:targetAddr]];
        m_socket.delegate = self;
    }
    return self;
}


- (void) receiver:(NSNotification * )notif {
    NSDictionary * dict = [messenger tagValueDictionaryFromNotification:notif];
    NSAssert(dict[@"operationId"], @"operationId required");
    
    
    if ([dict[@"operationId"] isEqualTo:m_operationId]) {

    } else {
        return;
    }
    
    switch ([messenger execFrom:[messenger myParentName] viaNotification:notif]) {
            
        case KS_WEBSOCKETCONNECTIONOPERATION_OPEN:{
            [m_socket open];
            break;
        }
            
        case KS_WEBSOCKETCONNECTIONOPERATION_CLOSE:{
            [m_socket close];
            m_socket.delegate = nil;
            break;
        }
            
        default:
            break;
    }
}




- (void)webSocketDidOpen:(SRWebSocket * )webSocket {
    [messenger callParent:KS_WEBSOCKETCONNECTIONOPERATION_ESTABLISHED,
     [messenger tag:@"operationId" val:m_operationId],
     nil];
}

- (void)webSocket:(SRWebSocket * )webSocket didFailWithError:(NSError * )error {
    
}

- (void)webSocket:(SRWebSocket * )webSocket didReceiveMessage:(id)message {
    [messenger callParent:KS_WEBSOCKETCONNECTIONOPERATION_RECEIVED,
     [messenger tag:@"operationId" val:m_operationId],
     [messenger tag:@"message" val:message],
     nil];
}

- (void)webSocket:(SRWebSocket * )webSocket didCloseWithCode:(NSInteger)code reason:(NSString * )reason wasClean:(BOOL)wasClean {
    
}


@end
