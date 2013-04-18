//
//  WebSocketController.h
//  
//
//  Created by 井上 徹 on 2013/02/14.
//  Copyright (c) 2013年 KISSAKI.inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KSMessenger.h"

#import "SRWebSocket.h"

#define KS_WEBSOCKETCONTROL (@"WSWEBSOCKETCONTROL")
typedef enum{
    KS_WEBSOCKETCONTROL_CONNECTTOA = 0,
    KS_WEBSOCKETCONTROL_CONNECTTOB,
    KS_WEBSOCKETCONTROL_OPENED,
    KS_WEBSOCKETCONTROL_SENDMESSAGE,
    KS_WEBSOCKETCONTROL_BROADCASTMESSAGE,
    
    KS_WEBSOCKETCONTROL_SET_TRANSMITMODE,
    
    KS_WEBSOCKETCONTROL_RECEIVEDMESSAGE,
    KS_WEBSOCKETCONTROL_FAILWITHERROR,
    KS_WEBSOCKETCONTROL_CLOSED
    
} TYPE_WebSocketControl;


@interface WebSocketController : NSObject <SRWebSocketDelegate> {
    KSMessenger * messenger;
    NSMutableDictionary * connectionDict;
}

- (id)initWebSocketControllerWithMasterName:(NSString * )masterName;

- (void) connectToA:(NSString * )connectTargetAddress withIdentity:(NSString * )connectionId;
- (void) connectToB:(NSString * )connectTargetAddress withIdentity:(NSString * )connectionId;
@end
