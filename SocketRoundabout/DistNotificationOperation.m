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
    

    int m_messageCount;
}

- (id) initDistNotificationOperationWithMaster:(NSString * )masterNameAndMID
                              withReceiverName:(NSString * )receiverName
                              withConnectionId:(NSString * )connectionId {
    if (self = [super init]) {
        messenger = [[KSMessenger alloc]initWithBodyID:self withSelector:@selector(receiver:) withName:KS_DISTRIBUTEDNOTIFICATIONOPERATION];
        [messenger connectParent:masterNameAndMID];
        
        m_operationId = [[NSString alloc]initWithString:connectionId];
        m_receiverName = [[NSString alloc]initWithString:receiverName];

        m_messageCount = 0;
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

            //idをつけて送付する。自分が出したものは受信してもなにもしない。
            m_messageCount++;

            //メッセージを、keyとvalueに分解する
            NSDictionary * messageDict = @{@"message":dict[@"message" ], KEY_DIST_COUNT:[NSNumber numberWithInt:m_messageCount]};
            [[NSDistributedNotificationCenter defaultCenter] postNotificationName:m_receiverName object:nil userInfo:messageDict deliverImmediately:YES];
            break;
        }
            
        case KS_DISTRIBUTEDNOTIFICATIONOPERATION_CLOSE:{
            [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
            [messenger closeConnection];
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
    
    
    if (userInfo[KEY_DIST_COUNT]) {
        //ポイントが存在し、現在の自分のカウントと同等だったら無視
        int receivedCount = [userInfo[KEY_DIST_COUNT] intValue];
        if (receivedCount == m_messageCount) {
            return;
        }
    }
    
    [self received:userInfo[@"message"]];
}

@end
