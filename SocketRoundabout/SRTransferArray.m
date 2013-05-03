//
//  SRTransferArray.m
//  SocketRoundabout
//
//  Created by sassembla on 2013/05/03.
//  Copyright (c) 2013年 KISSAKI Inc,. All rights reserved.
//

#import "SRTransferArray.h"
#import "SRTransfer.h"

@implementation SRTransferArray
- (NSString * )throughs:(NSString * )input {
    
    NSString * result = [[NSString alloc]initWithString:input];
    for (SRTransfer * trans in self) {
        result = [trans through:result];
    }
    return result;
}

@end
