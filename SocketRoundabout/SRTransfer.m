//
//  SRTransfer.m
//  SocketRoundabout
//
//  Created by sassembla on 2013/05/03.
//  Copyright (c) 2013年 KISSAKI Inc,. All rights reserved.
//

#import "SRTransfer.h"

/**
 変換オブジェクト、　in -> out 間で、文字列に対して変更を行う。
 */
@implementation SRTransfer {
    NSString * m_prefix;
    NSString * m_postfix;
}

- (id) initWithPrefix:(NSString * )prefix suffix:(NSString * )postfix {
    if (self = [super init]) {
        m_prefix = [[NSString alloc]initWithString:prefix];
        m_postfix = [[NSString alloc]initWithString:postfix];
    }
    return  self;
}

- (NSString * ) through:(NSString * )input {
    return [NSString stringWithFormat:@"%@%@%@", m_prefix, input, m_postfix];
}


@end
