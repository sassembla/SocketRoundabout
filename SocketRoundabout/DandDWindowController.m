//
//  DandDWindowController.m
//  SocketRoundabout
//
//  Created by sassembla on 2013/05/06.
//  Copyright (c) 2013年 KISSAKI Inc,. All rights reserved.
//

#import "DandDWindowController.h"

@interface DandDWindowController ()

@end

@implementation DandDWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        
    }

    return self;
}
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    return 0;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

@end
