//
//  AboutWindowController.m
//  Bubbles
//
//  Created by 吴 wuziqi on 12-2-28.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import "AboutWindowController.h"

@implementation AboutWindowController

- (id)init
{
    self = [super initWithWindowNibName:@"AboutWindowController"];
    if (self) {
        
    }
    return self;
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)dealloc
{
    [super dealloc];
}

@end
