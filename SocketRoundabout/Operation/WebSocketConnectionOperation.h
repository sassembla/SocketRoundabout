//
//  WebSocketConnectionOperation.h
//  SocketRoundabout
//
//  Created by sassembla on 2013/04/23.
//  Copyright (c) 2013年 KISSAKI Inc,. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SRWebSocket.h"


#define KS_WEBSOCKETCONNECTIONOPERATION (@"KS_WEBSOCKETCONNECTIONOPERATION")

typedef enum{
    KS_WEBSOCKETCONNECTIONOPERATION_OPEN = 0,
    KS_WEBSOCKETCONNECTIONOPERATION_ESTABLISHED,
    
    KS_WEBSOCKETCONNECTIONOPERATION_CLOSE
} TYPE_KS_WEBSOCKETCONNECTIONOPERATION;


@interface WebSocketConnectionOperation : NSObject <SRWebSocketDelegate>

- (id) initWebSocketConnectionOperationWithMaster:(NSString * )masterNameAndId withConnectionTarget:(NSString * )targetAddr withConnectionIdentity:(NSString * )connectionIdentity;
@end
