//
//  RoundaboutController.h
//  SocketRoundabout
//
//  Created by sassembla on 2013/04/23.
//  Copyright (c) 2013年 KISSAKI Inc,. All rights reserved.
//

#import <Cocoa/Cocoa.h>

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
    NSMutableDictionary * m_connections;
}

- (id) initWithMaster:(NSString * )masterNameAndId;
- (NSDictionary * ) connections;

- (void) outFrom:(NSString * )outputConnectionId into:(NSString * )inputConnectionId;

- (NSArray * ) outputsOf:(NSString * )connectionId;

- (NSArray * ) inputsOf:(NSString * )connectionId;

- (void) createWebSocketConnection:(NSString * )connectionTarget withConnectionId:(NSString * )connectionId;

- (void) roundabout:(NSString * )connectionId message:(NSString * )message;

- (int) transitOutputCount:(NSString * )connectionId;
- (int) transitInputCount:(NSString * )connectionid;
- (int) roundaboutMessageCount;

- (void) closeConnection:(NSString * )connectionId;
- (void) closeAllConnections;
- (void) exit;



//debug
- (void) directInput:(NSString * )connectionId message:(NSString * )message;

@end
