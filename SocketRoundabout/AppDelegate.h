//
//  AppDelegate.h
//  SocketRoundabout
//
//  Created by sassembla on 2013/04/17.
//  Copyright (c) 2013年 KISSAKI Inc,. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define SOCKETROUNDABOUT_MASTER (@"SOCKETROUNDABOUT_MASTER")

#define DEFAULT_SETTINGS    (@"socketroundabout.settings")

#define KEY_MASTER  (@"-m")
#define KEY_SETTING (@"-s")
#define PRIVATEKEY_BASEPATH (@"PRIVATEKEY_BASEPATH")


#define CODE_COMMENT    (@"//")
#define CODE_EMPTY      (@"")

#define DEFINE_LOADING_INTERVAL (0.00001)


#define CODE_DELIM          (@" ")

#define CODEHEAD_ID         (@"id:")
#define CODE_TYPE           (@"type:")
#define CODE_DESTINATION    (@"destination:")

#define CODEHEAD_CONNECT    (@"connect:")
#define CODE_TO             (@"to:")

#define CODEHEAD_TRANS      (@"trans:")
#define CODE_PREFIX         (@"prefix:")
#define CODE_POSTFIX        (@"postfix:")

typedef enum {
    SOCKETROUNDABOUT_MASTER_LOADSETTING_START = 0,
    SOCKETROUNDABOUT_MASTER_LOADSETTING_LOAD,
    SOCKETROUNDABOUT_MASTER_LOADSETTING_LOADING,
    SOCKETROUNDABOUT_MASTER_LOADSETTING_OVERED,
    SOCKETROUNDABOUT_MASTER_LOADSETTING_ERROR
} SOCKETROUNDABOUT_MASTER_EXECS;


@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;


- (id) initAppDelegateWithParam:(NSDictionary * )argsDict;
- (void) loadSetting;
- (void) exit;

@end
