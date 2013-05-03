//
//  SRTransferArray.m
//  SocketRoundabout
//
//  Created by sassembla on 2013/05/03.
//  Copyright (c) 2013年 KISSAKI Inc,. All rights reserved.
//

#import "SRTransferArray.h"


@implementation SRTransferArray {
    NSMutableArray * m_transferArray;
}

- (id) init {
    if (self = [super init]) {
        m_transferArray = [[NSMutableArray alloc]init];
    }
    return self;
}

- (void) addTransfer:(SRTransfer * )trans {
    [m_transferArray addObject:trans];
}

- (NSString * )throughs:(NSString * )input {
    
    NSString * result = [[NSString alloc]initWithString:input];
    for (SRTransfer * trans in m_transferArray) {
        result = [trans through:result];
    }
    return result;
}

- (NSArray * ) transfers {
    return m_transferArray;
}

@end
