//
//  AppDelegate.h
//  BubblesOnMac
//
//  Created by 王 得希 on 12-1-9.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WDBubble.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, WDBubbleDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (nonatomic, retain) IBOutlet NSTextField *textMessage;
@property (nonatomic, retain) IBOutlet NSImageView *imageMessage;

@property (nonatomic, retain) WDBubble *bubble;

@end
