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

@interface MainViewController : NSObject<WDBubbleDelegate,NSTableViewDelegate, NSTableViewDataSource,PasswordMacViewControllerDelegate>
{
    IBOutlet NSTextField *_textMessage;
    IBOutlet DragAndDropImageView *_imageMessage;
    IBOutlet NSTableView *_tableView;
    IBOutlet NSButton *_checkBox;
    
    WDBubble *_bubble;
    PasswordMacViewController *_passwordController;
}

@property (nonatomic, retain) IBOutlet NSTextField *textMessage;
@property (nonatomic, retain) IBOutlet DragAndDropImageView *imageMessage;
@property (nonatomic, retain) IBOutlet NSTableView *tableView;
@property (nonatomic, retain) IBOutlet NSButton *checkBox;

@property (nonatomic, retain) WDBubble *bubble;
@property (nonatomic, retain) PasswordMacViewController *passwordController;

-(IBAction)sendText:(id)sender;
-(IBAction)sendImage:(id)sender;
-(IBAction)saveImage:(id)sender;
-(IBAction)clickBox:(id)sender;
-(IBAction)BrowseImage:(id)sender;

@end
