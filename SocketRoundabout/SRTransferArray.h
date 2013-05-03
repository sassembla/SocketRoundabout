//
//  SRTransferArray.h
//  SocketRoundabout
//
//  Created by sassembla on 2013/05/03.
//  Copyright (c) 2013年 KISSAKI Inc,. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SRTransfer.h"

@interface SRTransferArray : NSObject
- (NSString * )throughs:(NSString * )input;
- (void) addTransfer:(SRTransfer * )trans;
- (NSArray * ) transfers;

@end
