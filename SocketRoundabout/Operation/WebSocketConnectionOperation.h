//
//  WebSocketConnectionOperation.h
//  SocketRoundabout
//
//  Created by sassembla on 2013/04/23.
//  Copyright (c) 2013年 KISSAKI Inc,. All rights reserved.
//

#import <Foundation/Foundation.h>

//client
#import "SRWebSocket.h"

//server
#import "MBWebSocketServer.h"

#define KS_WEBSOCKETCONNECTIONOPERATION (@"KS_WEBSOCKETCONNECTIONOPERATION")

#define KEY_WEBSOCKET_TYPE  (@"websocketas")

#define OPTION_TYPE_CLIENT  (@"client")
#define OPTION_TYPE_SERVER  (@"server")

#define WEBSOCKET_ADDRESS_DEFINE    (@"ws://")


typedef enum {
    KS_WEBSOCKETCONNECTIONOPERATION_OPEN = 0,
    KS_WEBSOCKETCONNECTIONOPERATION_ESTABLISHED,
    KS_WEBSOCKETCONNECTIONOPERATION_INPUT,
    KS_WEBSOCKETCONNECTIONOPERATION_RECEIVED,
    KS_WEBSOCKETCONNECTIONOPERATION_CLOSE
} TYPE_KS_WEBSOCKETCONNECTIONOPERATION;


typedef enum {
    WEBSOCKET_TYPE_SERVER,
    WEBSOCKET_TYPE_CLIENT,
} WEBSOCKET_TYPE;

@interface WebSocketConnectionOperation : NSObject <MBWebSocketServerDelegate, SRWebSocketDelegate>

- (id) initWebSocketConnectionOperationWithMaster:(NSString * )masterNameAndId withConnectionTarget:(NSString * )targetAddr withConnectionIdentity:(NSString * )connectionIdentity withOption:(NSDictionary * )opt;
- (void) received:(id)message;
@end
