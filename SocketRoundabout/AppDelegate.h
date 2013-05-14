//
//  AppDelegate.h
//  SocketRoundabout
//
//  Created by sassembla on 2013/04/17.
//  Copyright (c) 2013年 KISSAKI Inc,. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#define VERSION (0.8.1)


#define SOCKETROUNDABOUT_MASTER (@"SOCKETROUNDABOUT_MASTER")

#define DEFAULT_SETTINGS    (@"socketroundabout.settings")

#define KEY_MASTER  (@"-m")
#define KEY_SETTING (@"-s")
#define PRIVATEKEY_BASEPATH (@"PRIVATEKEY_BASEPATH")


#define CODE_COMMENT    (@"//")
#define CODE_EMPTY      (@"")

#define DEFINE_LOADING_INTERVAL (0.01)


#define CODE_DELIM          (@" ")
#define CODE_COMMA          (@",")
#define CODE_COLON          (@":")

#define CODEHEAD_ID         (@"id:")
#define CODE_TYPE           (@"type:")
#define CODE_DESTINATION    (@"destination:")
#define CODE_OPTION         (@"option:")

#define CODEHEAD_CONNECT    (@"connect:")
#define CODE_TO             (@"to:")

#define CODEHEAD_TRANS      (@"trans:")
#define CODE_PREFIX         (@"prefix:")
#define CODE_POSTFIX        (@"postfix:")

#define CODEHEAD_EMIT       (@"emit:")

#define CODEHEAD_EMITFILE   (@"emitfile:")

#define MARK_NO_CODEHEAD         (@"MARK_NO_CODEHEAD")

typedef enum {
    SOCKETROUNDABOUT_MASTER_NO_LOADSETTING = 0,
    SOCKETROUNDABOUT_MASTER_LOADSETTING_LOAD,
    SOCKETROUNDABOUT_MASTER_LOADSETTING_LOADING,
    SOCKETROUNDABOUT_MASTER_LOADSETTING_OVERED,
    SOCKETROUNDABOUT_MASTER_LOADSETTING_ERROR
} SOCKETROUNDABOUT_MASTER_EXECS;

//<NSDraggingSource, NSDraggingDestination, NSPasteboardItemDataProvider>
@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow * window;


- (id) initAppDelegateWithParam:(NSDictionary * )argsDict;
- (NSString * ) defaultSettingSource;
- (void) loadSetting:(NSString * )source;
- (void) exit;

@end
