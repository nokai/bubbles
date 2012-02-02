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
#import "PreferenceViewContoller.h"
#import "NSImage+QuickLook.h"

@interface MainViewController : NSObject <WDBubbleDelegate,NSTableViewDelegate, NSTableViewDataSource,PasswordMacViewControllerDelegate,DragAndDropImageViewDelegate> {
    WDBubble *_bubble;
    NSURL *_fileURL;
    
    IBOutlet NSTextField *_textMessage;
    IBOutlet DragAndDropImageView *_imageMessage;
    IBOutlet NSTableView *_tableView;
    IBOutlet NSButton *_checkBox;
    IBOutlet NSView *_accessoryView;
   
    PasswordMacViewController *_passwordController;
    PreferenceViewContoller *_preferenceController;
    
   

}

// DW: for binding
@property (nonatomic, retain) NSURL *fileURL;

@end
