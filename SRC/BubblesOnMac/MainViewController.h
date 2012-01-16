//
//  MainViewController.h
//  Bubbles
//
//  Created by 吴 wuziqi on 12-1-11.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WDBubble.h"
#import "PasswordMacViewController.h"
#import "DragAndDropImageView.h"

#define kMACUserDefaultsUsePassword @"kMACUserDefaultsUsePassword"

@interface MainViewController : NSObject<WDBubbleDelegate,NSTableViewDelegate, NSTableViewDataSource,PasswordMacViewControllerDelegate> {
    WDBubble *_bubble;
    
    IBOutlet NSTextField *_textMessage;
    IBOutlet DragAndDropImageView *_imageMessage;
    IBOutlet NSTableView *_tableView;
    IBOutlet NSButton *_checkBox;
    
    PasswordMacViewController *_passwordController;
}

@end
