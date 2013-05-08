//
//  DistNotificationOperation.h
//  SocketRoundabout
//
//  Created by sassembla on 2013/04/24.
//  Copyright (c) 2013年 KISSAKI Inc,. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KSMessenger.h"

#define KS_DISTRIBUTEDNOTIFICATIONOPERATION (@"KS_DISTRIBUTEDNOTIFICATIONOPERATION")

#define KEY_DIST_COUNT  (@"messageCount")

#define DEFAULT_OUTPUT_KEY  (@"message")


typedef enum TYPE_KS_DISTRIBUTEDNOTIFICATIONOPERATION {
    KS_DISTRIBUTEDNOTIFICATIONOPERATION_OPEN,
    KS_DISTRIBUTEDNOTIFICATIONOPERATION_ESTABLISHED,
    KS_DISTRIBUTEDNOTIFICATIONOPERATION_INPUT,
    KS_DISTRIBUTEDNOTIFICATIONOPERATION_RECEIVED,
    KS_DISTRIBUTEDNOTIFICATIONOPERATION_CLOSE
} TYPE_KS_DISTRIBUTEDNOTIFICATIONOPERATION;

@interface DistNotificationOperation : NSObject

- (id) initDistNotificationOperationWithMaster:(NSString * )masterNameAndMID
                              withReceiverName:(NSString * )receiverName
                              withConnectionId:(NSString * )connectionId
                                    withOption:(NSDictionary * )opt;
- (void) received:(id)message;
@end
