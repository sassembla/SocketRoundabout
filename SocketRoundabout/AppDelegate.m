//
//  AppDelegate.m
//  SocketRoundabout
//
//  Created by sassembla on 2013/04/17.
//  Copyright (c) 2013年 KISSAKI Inc,. All rights reserved.
//

#import "AppDelegate.h"
#import "KSMessenger.h"
#define SR_MASTER   (@"SocketRoundabout_MASTER")


@implementation AppDelegate {
    KSMessenger * messenger;
}

void uncaughtExceptionHandler(NSException *exception) {
    NSLog(@"CRASH: %@", exception);
    NSLog(@"Stack Trace: %@", [exception callStackSymbols]);
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
}
- (void) receiver:(NSNotification * )notif {
}

@end
