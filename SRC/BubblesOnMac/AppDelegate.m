//
//  AppDelegate.m
//  BubblesOnMac
//
//  Created by 王 得希 on 12-1-9.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

@synthesize textMessage, imageMessage, window = _window;
@synthesize bubble;

- (void)dealloc
{
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    self.bubble = [[WDBubble alloc] init];
    self.bubble.delegate = self;
    [self.bubble initSocket];
    [self.bubble publishServiceWithPassword:@""];
    [self.bubble browseServices];
}

- (IBAction)sendText:(id)sender {
    [self.bubble broadcastMessage:[WDMessage messageWithText:textMessage.stringValue]];
    [self.textMessage resignFirstResponder];
}

- (IBAction)saveImage:(id)sender {

}

- (IBAction)sendImage:(id)sender {

}

#pragma mark - WDBubbleDelegate

- (void)didReceiveText:(NSString *)text {
    DLog(@"VC didReceiveText %@", text);
    self.textMessage.stringValue = text;
}

- (void)didReceiveImage:(NSImage *)image {
    DLog(@"VC didReceiveImage %@", image);
    self.imageMessage.image = image;
}

#pragma mark - NSOutlineViewDelegate

#pragma mark - NSOutlineViewDataSource

@end
