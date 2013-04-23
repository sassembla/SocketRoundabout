//
//  RoundaboutController.m
//  SocketRoundabout
//
//  Created by sassembla on 2013/04/23.
//  Copyright (c) 2013年 KISSAKI Inc,. All rights reserved.
//

#import "RoundaboutController.h"
#import "WebSocketConnectionOperation.h"



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
            
            //辞書が既に同じ名前のconnectionを持っていなければ、socketConnectionOperationを新規に作成する。
            NSString * connectionTarget = dict[@"connectionTargetAddr"];
            NSString * connectionId = dict[@"connectionId"];

            
            if (m_connections[connectionId]) {
                [messenger callParent:KS_ROUNDABOUTCONT_CONNECT_ALREADYEXIST, nil];
            } else {
                WebSocketConnectionOperation * ope = [[WebSocketConnectionOperation alloc]initWebSocketConnectionOperationWithMaster:[messenger myNameAndMID] withConnectionTarget:connectionTarget withConnectionIdentity:connectionId];
                
                //set to connections
                [m_connections setValue:ope forKey:connectionId];
                
                
                //start connecting
                [messenger call:KS_WEBSOCKETCONNECTIONOPERATION withExec:KS_WEBSOCKETCONNECTIONOPERATION_OPEN,
                 [messenger tag:@"operationId" val:connectionId],
                 nil];
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
            
        default:
            break;
    }
    
    
}

- (NSArray * ) connections {
    return [m_connections allKeys];
}









- (void) close {
    
    
    //close all WebSocket Connections
    for (NSString * operationId in m_connections) {
        [messenger call:KS_WEBSOCKETCONNECTIONOPERATION withExec:KS_WEBSOCKETCONNECTIONOPERATION_CLOSE,
         [messenger tag:@"operationId" val:operationId],
         nil];
    }
    
    [m_connections removeAllObjects];
    
    [messenger closeConnection];
}



@end
