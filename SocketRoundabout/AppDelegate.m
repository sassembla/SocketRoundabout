//
//  AppDelegate.m
//  SocketRoundabout
//
//  Created by sassembla on 2013/04/17.
//  Copyright (c) 2013年 KISSAKI Inc,. All rights reserved.
//

#import "AppDelegate.h"
#import "KSMessenger.h"
#import "WebSocketController.h"

#define SR_MASTER   (@"SocketRoundabout_MASTER")


@implementation AppDelegate {
    KSMessenger * messenger;
    WebSocketController * wsCont;
}

void uncaughtExceptionHandler(NSException *exception) {
    NSLog(@"CRASH: %@", exception);
    NSLog(@"Stack Trace: %@", [exception callStackSymbols]);
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    

//    [self ignite];
    
//    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(rec:) name:@"TEST2013/04/24 16:20:51" object:nil];
}
- (void) rec:(NSNotification * )notif {
    NSLog(@"notif %@", notif);
}
- (void) ignite {
    /*
     2つ通信を発生させる。
     ひとつはローカルの127.0.0.1:8823
     もう一つはリモートのlambdaboutへ。
     アドレスの指定はinfo.plistでいいか。
     
     
     今は直書き。
     
     */
    NSString * ADDRESS_A = @"http://www.lambdabout.in";
    NSString * ADDRESS_B = @"ws://127.0.0.1:8823";
    
    NSString * CONNECTION_A = @"lambdabout";
    NSString * CONNECTION_B = @"local";
    
    
    messenger = [[KSMessenger alloc]initWithBodyID:self withSelector:@selector(receiver:) withName:SR_MASTER];
    wsCont = [[WebSocketController alloc]initWebSocketControllerWithMasterName:SR_MASTER];
    
    
    [messenger call:KS_WEBSOCKETCONTROL withExec:KS_WEBSOCKETCONTROL_CONNECTTOA,
     [messenger tag:@"targetURL" val:ADDRESS_A],
     [messenger tag:@"connectionId" val:CONNECTION_A],
     nil];
    
    [messenger call:KS_WEBSOCKETCONTROL withExec:KS_WEBSOCKETCONTROL_CONNECTTOB,
     [messenger tag:@"targetURL" val:ADDRESS_B],
     [messenger tag:@"connectionId" val:CONNECTION_B],
     nil];

}

- (void) receiver:(NSNotification * )notif {
    
    switch ([messenger execFrom:KS_WEBSOCKETCONTROL viaNotification:notif]) {
        case KS_WEBSOCKETCONTROL_OPENED:{
            NSLog(@"opened  %@", notif);
            break;
        }
            
        default:
            break;
    }
}

@end
