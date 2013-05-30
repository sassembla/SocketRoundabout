//
//  SRTransfer.h
//  SocketRoundabout
//
//  Created by sassembla on 2013/05/03.
//  Copyright (c) 2013年 KISSAKI Inc,. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SRTransfer : NSObject

- (id) initWithPrefix:(NSString * )prefix suffix:(NSString * )postfix;
- (NSString * )through:(NSString * )input;
@end
