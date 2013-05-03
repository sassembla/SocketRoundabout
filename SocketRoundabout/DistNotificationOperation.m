//
//  DistNotificationOperation.m
//  SocketRoundabout
//
//  Created by sassembla on 2013/04/24.
//  Copyright (c) 2013年 KISSAKI Inc,. All rights reserved.
//

#import "DistNotificationOperation.h"
#import "KSMessenger.h"

@implementation DistNotificationOperation {
    KSMessenger * messenger;
    NSString * m_operationId;
    NSString * m_receiverName;
}

- (id) initDistNotificationOperationWithMaster:(NSString * )masterNameAndMID
                              withReceiverName:(NSString * )receiverName
                              withConnectionId:(NSString * )connectionId {
    if (self = [super init]) {
        messenger = [[KSMessenger alloc]initWithBodyID:self withSelector:@selector(receiver:) withName:KS_DISTRIBUTEDNOTIFICATIONOPERATION];
        [messenger connectParent:masterNameAndMID];
        
        m_operationId = [[NSString alloc]initWithString:connectionId];
        m_receiverName = [[NSString alloc]initWithString:receiverName];
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
            
        case KS_DISTRIBUTEDNOTIFICATIONOPERATION_OPEN:{

            [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(notifReceiver:) name:m_receiverName object:nil];
            
            [messenger callParent:KS_DISTRIBUTEDNOTIFICATIONOPERATION_ESTABLISHED,
             [messenger tag:@"operationId" val:m_operationId],
             nil];
            break;
        }
            
        case KS_DISTRIBUTEDNOTIFICATIONOPERATION_INPUT:{
            NSAssert(dict[@"message"], @"message required");
            NSAssert(false, @"DistributedNotification-operation does not support emit message.");
            break;
        }
            
        case KS_DISTRIBUTEDNOTIFICATIONOPERATION_CLOSE:{
            [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
            break;
        }
            
        default:
            
            break;
    }
}

- (void) received:(id)message {
    [messenger callParent:KS_DISTRIBUTEDNOTIFICATIONOPERATION_RECEIVED,
     [messenger tag:@"operationId" val:m_operationId],
     [messenger tag:@"message" val:message],
     nil];
}

- (void) notifReceiver:(NSNotification * )notif {
    NSDictionary * userInfo = [notif userInfo];
    
    NSAssert(userInfo[@"message"], @"message required");
    [self received:userInfo[@"message"]];
}

@end
