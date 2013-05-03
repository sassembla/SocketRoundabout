//
//  SocketRoundabout.m
//  SocketRoundabout
//
//  Created by sassembla on 2013/05/03.
//  Copyright (c) 2013年 KISSAKI Inc,. All rights reserved.
//

#import "SocketRoundabout.h"
#import "AppDelegate.h"

#define KEY_PERFIX  (@"-")

@implementation SocketRoundabout

int NSApplicationMain(int argc, const char *argv[]) {
    @autoreleasepool {
        NSMutableArray * keyAndValueStrArray = [[NSMutableArray alloc]init];
        
        for (int i = 0; i < argc; i++) {
            
            [keyAndValueStrArray addObject:[NSString stringWithUTF8String:argv[i]]];
            
        }
        
        NSMutableDictionary * argsDict = [[NSMutableDictionary alloc]init];
        
        for (int i = 0; i < [keyAndValueStrArray count]; i++) {
            NSString * keyOrValue = keyAndValueStrArray[i];
            if ([keyOrValue hasPrefix:KEY_PERFIX]) {
                NSString * key = keyOrValue;
                
                // get value
                if (i + 1 < [keyAndValueStrArray count]) {
                    NSString * value = keyAndValueStrArray[i + 1];
                    if ([value hasPrefix:KEY_PERFIX]) {
                        [argsDict setValue:@"" forKey:key];
                    } else {
                        [argsDict setValue:value forKey:key];
                    }
                }
                else {
                    NSString * value = @"";
                    [argsDict setValue:value forKey:key];
                }
            }
        }
        
        if (argsDict[KEY_SETTING]) {
            
        } else {
            NSString * appPAth = keyAndValueStrArray[0];
            NSString * appBasePath = [appPAth stringByDeletingLastPathComponent];
            [argsDict setValue:appBasePath forKey:PRIVATEKEY_BASEPATH];
            NSLog(@"appBasePath %@", appBasePath);
        }
        
        
        AppDelegate * delegate = [[AppDelegate alloc] initAppDelegateWithParam:argsDict];
        
        NSApplication * application = [NSApplication sharedApplication];
        [application setDelegate:delegate];
        
        [NSApp run];

        return 0;
    }
    
}
@end
