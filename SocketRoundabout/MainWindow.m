//
//  MainWindow.m
//  SocketRoundabout
//
//  Created by sassembla on 2013/05/07.
//  Copyright (c) 2013年 KISSAKI Inc,. All rights reserved.
//

#import "MainWindow.h"
#import "KSMessenger.h"

#import "RoundaboutController.h"
#define PREFIX_FILE (@"file://")

@implementation MainWindow {
    KSMessenger * messenger;
}


- (void) awakeFromNib {
    [self registerForDraggedTypes:@[NSFilenamesPboardType]];
    
    messenger = [[KSMessenger alloc]initWithBodyID:self withSelector:@selector(receiver:) withName:SOCKETROUNDABOUT_MAINWINDOW];
    [messenger connectParent:KS_ROUNDABOUTCONT];
}

- (void) receiver:(NSNotification * )notif {}


- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender {
    return NSDragOperationLink;
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
    return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    NSPasteboard * p = [sender draggingPasteboard];
    
    for (NSPasteboardItem * item in [p pasteboardItems]) {
        NSString * uri = [item stringForType:[item types][0]];
        
        if ([uri hasPrefix:PREFIX_FILE]) {
            [messenger callParent:SOCKETROUNDABOUT_MAINWINDOW_INPUT_URI,
             [messenger tag:@"uri" val:uri],
             nil];
        }
    }
    
    return YES;
}


@end
