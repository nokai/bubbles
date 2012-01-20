//
//  PreferenceViewContoller.h
//  Bubbles
//
//  Created by 吴 wuziqi on 12-1-20.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define KUserDefaultSavingPath @"KUserDefaultSavingPath"

@interface PreferenceViewContoller : NSWindowController
{
    IBOutlet NSPopUpButton *_savePathButton;
}

@end
