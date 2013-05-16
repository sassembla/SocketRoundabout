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
    
    int m_websocket_type;
    
    //behave as client
    SRWebSocket * m_client;
    
    //behave as server
    MBWebSocketServer * m_server;
}

- (id) initWebSocketConnectionOperationWithMaster:(NSString * )masterNameAndId withConnectionTarget:(NSString * )targetAddr withConnectionIdentity:(NSString * )connectionIdentity withOption:(NSDictionary * )opt {
    if (self = [super init]) {
        messenger = [[KSMessenger alloc]initWithBodyID:self withSelector:@selector(receiver:) withName:KS_WEBSOCKETCONNECTIONOPERATION];
        
        [messenger connectParent:masterNameAndId];
        
        m_operationId = [[NSString alloc]initWithString:connectionIdentity];
        
        
        if ([opt[KEY_WEBSOCKET_TYPE] isEqualToString:OPTION_TYPE_CLIENT]) {
            m_websocket_type = WEBSOCKET_TYPE_CLIENT;
        } else {
            m_websocket_type = WEBSOCKET_TYPE_SERVER;
        }
        
        //initialize
        switch (m_websocket_type) {
            case WEBSOCKET_TYPE_SERVER:{
                NSInteger port = [targetAddr integerValue];
                NSAssert2(0 < port, @"failed to initialize WebSocket-server, named:%@ port:%@", connectionIdentity, targetAddr);
                
                m_server = [[MBWebSocketServer alloc]initWithPort:port delegate:self];
                NSAssert(m_server, @"failed to start serving, named:%@", connectionIdentity);
                break;
            }

            case WEBSOCKET_TYPE_CLIENT:{
                m_client = [[SRWebSocket alloc]initWithURL:[NSURL URLWithString:targetAddr]];
                m_client.delegate = self;
                break;
            }
                            
            default:
                break;
        }
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
    
    
    switch (m_websocket_type) {
        case WEBSOCKET_TYPE_SERVER:{
            
            switch ([messenger execFrom:[messenger myParentName] viaNotification:notif]) {
                    
                case KS_WEBSOCKETCONNECTIONOPERATION_OPEN:{
                    [messenger callParent:KS_WEBSOCKETCONNECTIONOPERATION_ESTABLISHED,
                     [messenger tag:@"operationId" val:m_operationId],
                     nil];
                    break;
                }
                    
                case KS_WEBSOCKETCONNECTIONOPERATION_INPUT:{
                    NSAssert(dict[@"message"], @"message required");
                    [m_server send:dict[@"message"]];
                    break;
                }
                    
                case KS_WEBSOCKETCONNECTIONOPERATION_CLOSE:{
                    [m_server disconnect];
                    [messenger closeConnection];
                    break;
                }
                    
                default:
                    break;
            }

            break;
        }
        case WEBSOCKET_TYPE_CLIENT:{
            switch ([messenger execFrom:[messenger myParentName] viaNotification:notif]) {
                    
                case KS_WEBSOCKETCONNECTIONOPERATION_OPEN:{
                    [m_client open];
                    break;
                }
                    
                case KS_WEBSOCKETCONNECTIONOPERATION_INPUT:{
                    NSAssert(dict[@"message"], @"message required");
                    [m_client send:dict[@"message"]];
                    break;
                }
                    
                case KS_WEBSOCKETCONNECTIONOPERATION_CLOSE:{
                    [m_client close];
                    m_client.delegate = nil;
                    [messenger closeConnection];
                    break;
                }
                    
                default:
                    break;
            }
            break;
        }
        default:
            break;
    }   
}

- (void) received:(id)message {
    [messenger callParent:KS_WEBSOCKETCONNECTIONOPERATION_RECEIVED,
     [messenger tag:@"operationId" val:m_operationId],
     [messenger tag:@"message" val:message],
     nil];
}


/**
 delegate act as client
 */
- (void)webSocketDidOpen:(SRWebSocket * )webSocket {
    [messenger callParent:KS_WEBSOCKETCONNECTIONOPERATION_ESTABLISHED,
     [messenger tag:@"operationId" val:m_operationId],
     nil];
}

- (void)webSocket:(SRWebSocket * )webSocket didFailWithError:(NSError * )error {}

- (void)webSocket:(SRWebSocket * )webSocket didReceiveMessage:(id)message {
    [self received:message];
}

- (void)webSocket:(SRWebSocket * )webSocket didCloseWithCode:(NSInteger)code reason:(NSString * )reason wasClean:(BOOL)wasClean {}


/**
 delegate act as server
 */
- (void)webSocketServer:(MBWebSocketServer *)webSocketServer didAcceptConnection:(GCDAsyncSocket *)connection {}
- (void)webSocketServer:(MBWebSocketServer *)webSocketServer clientDisconnected:(GCDAsyncSocket *)connection {}
- (void)webSocketServer:(MBWebSocketServer *)webSocket didReceiveData:(NSData *)data fromConnection:(GCDAsyncSocket *)connection {
    NSString * message = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    [self received:message];
}

- (void)webSocketServer:(MBWebSocketServer *)webSocketServer couldNotParseRawData:(NSData *)rawData fromConnection:(GCDAsyncSocket *)connection error:(NSError *)error {}


@end
