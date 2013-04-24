//
//  RoundaboutController.m
//  SocketRoundabout
//
//  Created by sassembla on 2013/04/23.
//  Copyright (c) 2013年 KISSAKI Inc,. All rights reserved.
//

#import "RoundaboutController.h"

#import "WebSocketConnectionOperation.h"
#import "DistNotificationOperation.h"


@implementation RoundaboutController

- (id) initWithMaster:(NSString * )masterNameAndId {
    if (self = [super init]) {
        messenger = [[KSMessenger alloc]initWithBodyID:self withSelector:@selector(receiver:) withName:KS_ROUNDABOUTCONT];
        [messenger connectParent:masterNameAndId];
        
        m_connections = [[NSMutableDictionary alloc]init];
    }
    return self;
}

- (void) receiver:(NSNotification * )notif {
    NSDictionary * dict = [messenger tagValueDictionaryFromNotification:notif];
    
    switch ([messenger execFrom:[messenger myParentName] viaNotification:notif]) {
        case KS_ROUNDABOUTCONT_CONNECT:{
            NSAssert(dict[@"connectionTargetAddr"], @"connectionTarget required");
            NSAssert(dict[@"connectionId"], @"connectionId required");
            NSAssert(dict[@"connectionType"], @"connectionType required");
            
            //辞書が既に同じ名前のconnectionを持っていなければ、socketConnectionOperationを新規に作成する。
            NSString * connectionTarget = dict[@"connectionTargetAddr"];
            NSString * connectionId = dict[@"connectionId"];
            NSNumber * connectionType = dict[@"connectionType"];
            
            if (m_connections[connectionId]) {
                [messenger callParent:KS_ROUNDABOUTCONT_CONNECT_ALREADYEXIST, nil];
            } else {
                switch ([connectionType intValue]) {
                    case KS_ROUNDABOUTCONT_CONNECTION_TYPE_WEBSOCKET:{
                        [self createWebSocketConnection:connectionTarget withConnectionId:connectionId];
                        break;
                    }
                        
                    case KS_ROUNDABOUTCONT_CONNECTION_TYPE_NOTIFICATION:{
                        [self createNotificationReceiver:connectionTarget withConnectionId:connectionId];
                        break;
                    }
                        
                    default:
                        break;
                }
                
            }
            break;
        }
            
        default:
            break;
    }
    
    
    
    
    switch ([messenger execFrom:KS_WEBSOCKETCONNECTIONOPERATION viaNotification:notif]) {
        case KS_WEBSOCKETCONNECTIONOPERATION_ESTABLISHED:{
            NSAssert(dict[@"operationId"], @"operationId required");
            [messenger callParent:KS_ROUNDABOUTCONT_CONNECT_ESTABLISHED,
             [messenger tag:@"connectionId" val:dict[@"operationId"]],
             nil];
            break;
        }
            
        case KS_WEBSOCKETCONNECTIONOPERATION_RECEIVED:{
            NSAssert(dict[@"message"], @"message required");
            NSLog(@"ws message %@", dict[@"message"]);
            break;
        }
            
        default:
            break;
    }
    
    
    
    
    switch ([messenger execFrom:KS_DISTRIBUTEDNOTIFICATIONOPERATION viaNotification:notif]) {
        case KS_DISTRIBUTEDNOTIFICATIONOPERATION_ESTABLISHED:{
            NSAssert(dict[@"operationId"], @"operationId required");
            [messenger callParent:KS_ROUNDABOUTCONT_CONNECT_ESTABLISHED,
             [messenger tag:@"connectionId" val:dict[@"operationId"]],
             nil];
            break;
        }
            
        case KS_DISTRIBUTEDNOTIFICATIONOPERATION_RECEIVED:{
            NSAssert(dict[@"message"], @"message required");
            NSLog(@"notif message %@", dict[@"message"]);
            break;
        }
            
        default:
            break;
    }
    
    
}


- (void) createWebSocketConnection:(NSString * )connectionTarget withConnectionId:(NSString * )connectionId {
    WebSocketConnectionOperation * ope = [[WebSocketConnectionOperation alloc]initWebSocketConnectionOperationWithMaster:[messenger myNameAndMID] withConnectionTarget:connectionTarget withConnectionIdentity:connectionId];
    
    NSDictionary * connectionDict = @{@"connector": ope,
                                      @"connectionTarget": connectionTarget,
                                      @"connectionType": [NSNumber numberWithInt:KS_ROUNDABOUTCONT_CONNECTION_TYPE_WEBSOCKET]};

    
    //set to connections
    [m_connections setValue:connectionDict forKey:connectionId];
    
    
    //start connecting
    [messenger call:KS_WEBSOCKETCONNECTIONOPERATION withExec:KS_WEBSOCKETCONNECTIONOPERATION_OPEN,
     [messenger tag:@"operationId" val:connectionId],
     nil];
}

- (void) createNotificationReceiver:(NSString * )receiverName withConnectionId:(NSString * )connectionId {
    DistNotificationOperation * distNotifOpe = [[DistNotificationOperation alloc] initDistNotificationOperationWithMaster:[messenger myNameAndMID] withReceiverName:receiverName withConnectionId:connectionId];
    
    NSDictionary * connectionDict = @{@"connector": distNotifOpe,
                                      @"connectionTarget": receiverName,
                                      @"connectionType": [NSNumber numberWithInt:KS_ROUNDABOUTCONT_CONNECTION_TYPE_NOTIFICATION]};
    
    //set to connections
    [m_connections setValue:connectionDict forKey:connectionId];
    
    
    //start connecting
    [messenger call:KS_WEBSOCKETCONNECTIONOPERATION withExec:KS_WEBSOCKETCONNECTIONOPERATION_OPEN,
     [messenger tag:@"operationId" val:connectionId],
     nil];
}



- (NSDictionary * ) connections {
    NSArray * keys = [m_connections allKeys];
    return [m_connections dictionaryWithValuesForKeys:keys];
}


- (void) closeConnection:(NSString * )connectionId {
    int connectionType = [m_connections[connectionId][@"connectionType"] intValue];
    
    switch (connectionType) {
        case KS_ROUNDABOUTCONT_CONNECTION_TYPE_WEBSOCKET:{
            [messenger call:KS_WEBSOCKETCONNECTIONOPERATION withExec:KS_WEBSOCKETCONNECTIONOPERATION_CLOSE,
             [messenger tag:@"operationId" val:connectionId],
             nil];
            break;
        }
        
        case KS_ROUNDABOUTCONT_CONNECTION_TYPE_NOTIFICATION:{
            NSAssert(false, @"まだ閉じてない");
            break;
        }
            
        default:
            break;
    }
    
    
    [m_connections removeObjectForKey:connectionId];
}

- (void) closeAllConnections {
    //close all WebSocket Connections
    NSArray * connectionsKeys = [[NSArray alloc]initWithArray:[m_connections allKeys]];
    for (NSString * connectionId in connectionsKeys) {
        [self closeConnection:connectionId];
    }
}

- (void) exit {
    [self closeAllConnections];
    
    [messenger closeConnection];
}

@end
