//
//  MainWindow.h
//  SocketRoundabout
//
//  Created by sassembla on 2013/05/07.
//  Copyright (c) 2013年 KISSAKI Inc,. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define SOCKETROUNDABOUT_MAINWINDOW   (@"SOCKETROUNDABOUT_MAINWINDOW")

typedef enum {
    SOCKETROUNDABOUT_MAINWINDOW_INPUT_URI = 0
} SOCKETROUNDABOUT_MAINWINDOW_EXECS;

@interface MainWindow : NSWindow <NSDraggingDestination>

@end
