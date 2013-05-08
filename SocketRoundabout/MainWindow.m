//
//  MainWindow.m
//  SocketRoundabout
//
//  Created by sassembla on 2013/05/07.
//  Copyright (c) 2013年 KISSAKI Inc,. All rights reserved.
//

#import "MainWindow.h"
#import "KSMessenger.h"

#import "AppDelegate.h"
#define PREFIX_FILE (@"file://localhost")

@implementation MainWindow {
    KSMessenger * messenger;
}


- (void) awakeFromNib {
    [self registerForDraggedTypes:@[NSFilenamesPboardType]];
    
    messenger = [[KSMessenger alloc]initWithBodyID:self withSelector:@selector(receiver:) withName:SOCKETROUNDABOUT_MAINWINDOW];
    [messenger connectParent:SOCKETROUNDABOUT_MASTER];
}

- (void) receiver:(NSNotification * )notif {
    switch ([messenger execFrom:[messenger myParentName] viaNotification:notif]) {
        case SOCKETROUNDABOUT_MASTER_LOADSETTING_OVERED:{
            NSLog(@"load succeeded!");
            break;
        }
            
        default:
            break;
    }
}


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
            NSArray * protocolAndUri = [uri componentsSeparatedByString:PREFIX_FILE];
            
            [messenger callParent:SOCKETROUNDABOUT_MAINWINDOW_INPUT_URI,
             [messenger tag:@"uri" val:protocolAndUri[1]],
             nil];
        }
        
        break;
    }
    
    return YES;
}


@end
