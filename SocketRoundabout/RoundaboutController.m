//
//  RoundaboutController.m
//  SocketRoundabout
//
//  Created by sassembla on 2013/04/23.
//  Copyright (c) 2013年 KISSAKI Inc,. All rights reserved.
//

#import "RoundaboutController.h"
#import "KSMessenger.h"

#import "WebSocketConnectionOperation.h"
#import "DistNotificationOperation.h"

#import "SRTransfer.h"
#import "SRTransferArray.h"

#define ROUNDABOUT_DEBUG   (true)
@implementation RoundaboutController {
    KSMessenger * messenger;
    NSMutableDictionary * m_transitDebugDataDict;
    int m_messageCount;
    NSMutableDictionary * m_transferDict;
}

- (id) initWithMaster:(NSString * )masterNameAndId {
    if (self = [super init]) {
        messenger = [[KSMessenger alloc]initWithBodyID:self withSelector:@selector(receiver:) withName:KS_ROUNDABOUTCONT];
        [messenger connectParent:masterNameAndId];
        
        m_connections = [[NSMutableDictionary alloc]init];
        m_transferDict = [[NSMutableDictionary alloc]init];
        if (ROUNDABOUT_DEBUG) m_transitDebugDataDict = [[NSMutableDictionary alloc]init];
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
            NSAssert(dict[@"operationId"], @"operationId required");
            NSAssert(dict[@"message"], @"message required");
            
            NSString * connectionId = dict[@"operationId"];
            NSString * message = dict[@"message"];
            
            m_messageCount++;
            
            [self roundabout:connectionId message:message];
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
            NSAssert(dict[@"operationId"], @"operationId required");
            NSAssert(dict[@"message"], @"message required");
            
            NSString * connectionId = dict[@"operationId"];
            NSString * message = dict[@"message"];
            
            m_messageCount++;
            
            [self roundabout:connectionId message:message];
            break;
        }
        
        default:
            break;
    }
    
    
}



- (void) createWebSocketConnection:(NSString * )connectionTarget withConnectionId:(NSString * )connectionId {
    WebSocketConnectionOperation * ope = [[WebSocketConnectionOperation alloc]initWebSocketConnectionOperationWithMaster:[messenger myNameAndMID] withConnectionTarget:connectionTarget withConnectionIdentity:connectionId];
    
    NSMutableArray * outArray = [[NSMutableArray alloc]init];
    NSMutableArray * inArray = [[NSMutableArray alloc]init];
    
    NSDictionary * connectionDict = @{@"connector": ope,
                                      @"connectionTarget": connectionTarget,
                                      @"connectionType": [NSNumber numberWithInt:KS_ROUNDABOUTCONT_CONNECTION_TYPE_WEBSOCKET],
                                      @"connectionOutputs":outArray,
                                      @"connectionInputs":inArray};

    
    //set to connections
    [m_connections setValue:connectionDict forKey:connectionId];
    
    
    //start connecting
    [messenger call:KS_WEBSOCKETCONNECTIONOPERATION withExec:KS_WEBSOCKETCONNECTIONOPERATION_OPEN,
     [messenger tag:@"operationId" val:connectionId],
     nil];
}

- (void) createNotificationReceiver:(NSString * )receiverName withConnectionId:(NSString * )connectionId {

    DistNotificationOperation * distNotifOpe = [[DistNotificationOperation alloc] initDistNotificationOperationWithMaster:[messenger myNameAndMID] withReceiverName:receiverName withConnectionId:connectionId];
    
    NSMutableArray * outArray = [[NSMutableArray alloc]init];
    NSMutableArray * inArray = [[NSMutableArray alloc]init];
    
    NSDictionary * connectionDict = @{@"connector": distNotifOpe,
                                      @"connectionTarget": receiverName,
                                      @"connectionType": [NSNumber numberWithInt:KS_ROUNDABOUTCONT_CONNECTION_TYPE_NOTIFICATION],
                                      @"connectionOutputs":outArray,
                                      @"connectionInputs":inArray};
    
    //set to connections
    [m_connections setValue:connectionDict forKey:connectionId];
    
    
    //start connecting
    [messenger call:KS_DISTRIBUTEDNOTIFICATIONOPERATION withExec:KS_DISTRIBUTEDNOTIFICATIONOPERATION_OPEN,
     [messenger tag:@"operationId" val:connectionId],
     nil];
}



- (NSDictionary * ) connections {
    NSArray * keys = [m_connections allKeys];
    return [m_connections dictionaryWithValuesForKeys:keys];
}


- (void) outFrom:(NSString * )outputConnectionId into:(NSString * )inputConnectionId {
    NSAssert1(m_connections[outputConnectionId], @"no output connection with given id, %@", outputConnectionId);
    NSAssert1(m_connections[inputConnectionId], @"no input connection with given id, %@", inputConnectionId);
    
    NSMutableArray * outputs = m_connections[outputConnectionId][@"connectionOutputs"];
    NSMutableArray * inputs = m_connections[inputConnectionId][@"connectionInputs"];
    
    if ([outputs containsObject:inputConnectionId]) {
        
    } else {
        [outputs addObject:inputConnectionId];
    }
    
    
    if ([inputs containsObject:outputConnectionId]) {
        
    } else {
        [inputs addObject:outputConnectionId];
    }
}


/**
 from:to 形式のtransferのidentity生成ルール
 */
- (NSString * ) transferIdentityByFrom:(NSString * )from to:(NSString * )to {
    return [NSString stringWithFormat:@"%@:%@",from,to];
}


/**
 特定の接続に対して、存在すればtransferを設定する。
 */
- (void) setTransferFrom:(NSString * )from to:(NSString * )to prefix:(NSString * )prefix postfix:(NSString * )postfix {
    NSMutableArray * outputs = m_connections[from][@"connectionOutputs"];
    NSMutableArray * inputs = m_connections[to][@"connectionInputs"];
    
    NSAssert([outputs containsObject:from], @"no output exist:%@", from);
    NSAssert([inputs containsObject:to], @"no input exist:%@", to);

    NSString * fromto = [self transferIdentityByFrom:from to:to];
    
    SRTransfer * trans = [[SRTransfer alloc]initWithPrefix:prefix postfix:postfix];
    
    if (m_transferDict[fromto]) {}
    else {
        SRTransferArray * array = [[SRTransferArray alloc]init];
        [m_transferDict setValue:array forKey:fromto];
    }
    
    //追加
    [m_transferDict[fromto] addObject:trans];
}

/**
 transferArrayを返す
 */
- (NSArray * )transferFrom:(NSString * )output to:(NSString * )input {
    return [NSArray arrayWithArray:m_transferDict[[self transferIdentityByFrom:output to:input]]];
}

- (NSArray * ) outputsOf:(NSString * )connectionId {
    NSAssert1(m_connections[connectionId], @"no connection with given id, %@", connectionId);
    return m_connections[connectionId][@"connectionOutputs"];
}

- (NSArray * ) inputsOf:(NSString * )connectionId {
    NSAssert1(m_connections[connectionId], @"no connection with given id, %@", connectionId);
    return m_connections[connectionId][@"connectionInputs"];
}


- (void) roundabout:(NSString * )connectionId message:(NSString * )message {
    if (ROUNDABOUT_DEBUG) {
        int outputCount = 0;
       
        if (m_transitDebugDataDict[connectionId]) {
            outputCount = [m_transitDebugDataDict[connectionId][@"outputCount"] intValue];
        } else {
            NSMutableDictionary * dict = [[NSMutableDictionary alloc]init];
            [dict setValue:@0 forKey:@"outputCount"];
            [m_transitDebugDataDict setValue:dict forKey:connectionId];
        }
        
        //roundabout message from output to input
        //sender
        for (NSString * targetConnectionId in m_connections[connectionId][@"connectionOutputs"]) {
            
            int inputCount = 0;
            if (ROUNDABOUT_DEBUG) {
                if (m_transitDebugDataDict[targetConnectionId]) {
                    inputCount = [m_transitDebugDataDict[targetConnectionId][@"inputCount"] intValue];
                } else {
                    NSMutableDictionary * dict = [[NSMutableDictionary alloc]init];
                    [dict setValue:@0 forKey:@"inputCount"];
                    [m_transitDebugDataDict setValue:dict forKey:targetConnectionId];
                }
            }
            
            
            //receiver
            NSArray * connectionInputsArray = m_connections[targetConnectionId][@"connectionInputs"];
            if ([connectionInputsArray containsObject:connectionId]) {
                outputCount = outputCount+1;
                inputCount = inputCount+1;
                
                //transfer
                if (0 < [m_transferDict[[self transferFrom:connectionId to:targetConnectionId]] count]) {
                    SRTransferArray * transfers = m_transferDict[[self transferFrom:connectionId to:targetConnectionId]];
                    message = [transfers throughs:message];
                }
                
                [self input:targetConnectionId message:message];
            }
            
            if (ROUNDABOUT_DEBUG) {
                NSMutableDictionary * currentReceiverDict = m_transitDebugDataDict[targetConnectionId];
                [currentReceiverDict setValue:[NSNumber numberWithInt:inputCount] forKey:@"inputCount"];
            }
        }
        
        if (ROUNDABOUT_DEBUG) {
            NSMutableDictionary * currentSenderDict = m_transitDebugDataDict[connectionId];
            [currentSenderDict setValue:[NSNumber numberWithInt:outputCount] forKey:@"outputCount"];
        }
    }
}


- (void) input:(NSString * )connectionId message:(NSString * )message {
    NSAssert1(m_connections[connectionId], @"input: connectionId is not valid, %@", connectionId);
    NSString * connectionType;
    int connectionSendExec = 0;
    
    switch ([m_connections[connectionId][@"connectionType"] intValue]) {
        case KS_ROUNDABOUTCONT_CONNECTION_TYPE_WEBSOCKET:{
            connectionType = KS_WEBSOCKETCONNECTIONOPERATION;
            connectionSendExec = KS_WEBSOCKETCONNECTIONOPERATION_INPUT;
            break;
        }
            
        case KS_ROUNDABOUTCONT_CONNECTION_TYPE_NOTIFICATION:{
            connectionType = KS_DISTRIBUTEDNOTIFICATIONOPERATION;
            connectionSendExec = KS_DISTRIBUTEDNOTIFICATIONOPERATION_INPUT;
            break;
        }
        
        default:
            break;
    }
    
    //send
    [messenger call:connectionType withExec:connectionSendExec,
     [messenger tag:@"operationId" val:connectionId],
     [messenger tag:@"message" val:message],
     nil];
    
}



- (int) transitOutputCount:(NSString * )connectionId {
    return [m_transitDebugDataDict[connectionId][@"outputCount"] intValue];
}

- (int) transitInputCount:(NSString * )connectionid {
    return [m_transitDebugDataDict[connectionid][@"inputCount"] intValue];
}


- (int) roundaboutMessageCount {
    return m_messageCount;
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
            [messenger call:KS_DISTRIBUTEDNOTIFICATIONOPERATION withExec:KS_DISTRIBUTEDNOTIFICATIONOPERATION_CLOSE,
             [messenger tag:@"operationId" val:connectionId],
             nil];
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





/**
 DEBUG method. only for testing.
 */
- (void) directInput:(NSString * )connectionId message:(NSString * )message {
    [self input:connectionId message:message];
}

@end
