//
//  RoundaboutController.h
//  SocketRoundabout
//
//  Created by sassembla on 2013/04/23.
//  Copyright (c) 2013年 KISSAKI Inc,. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KSMessenger.h"

#define KS_ROUNDABOUTCONT   (@"KS_ROUNDABOUTCONT")


typedef enum {
    KS_ROUNDABOUTCONT_CONNECTION_TYPE_WEBSOCKET = 0,
    KS_ROUNDABOUTCONT_CONNECTION_TYPE_NOTIFICATION
} KS_ROUNDABOUTCONT_CONNECTION_TYPE;

typedef enum {
    KS_ROUNDABOUTCONT_CONNECT = 0,
    KS_ROUNDABOUTCONT_CONNECT_ESTABLISHED,
    KS_ROUNDABOUTCONT_CONNECT_ALREADYEXIST,
    KS_ROUNDABOUTCONT_CLOSE
    
} KS_ROUNDABOUTCONT_EXEC;

@interface RoundaboutController : NSObject {
    KSMessenger * messenger;
    NSMutableDictionary * m_connections;
}

- (id) initWithMaster:(NSString * )masterNameAndId;
- (NSDictionary * ) connections;

- (void) createWebSocketConnection:(NSString * )connectionTarget withConnectionId:(NSString * )connectionId;


- (void) closeConnection:(NSString * )connectionId;
- (void) closeAllConnections;
- (void) exit;

@end
