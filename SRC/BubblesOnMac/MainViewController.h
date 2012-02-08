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
#import "DragFileViewController.h"
#import "PreferenceViewContoller.h"
#import "NSImage+QuickLook.h"
#import "ImageAndTextCell.h"
#import "TextViewController.h"
#import <QuartzCore/QuartzCore.h>

#define kTextViewController 0
#define kDragFileController 1

@interface MainViewController : NSObject <WDBubbleDelegate,NSTableViewDelegate, NSTableViewDataSource,PasswordMacViewControllerDelegate,ImageAndTextCellDelegate,DragAndDropImageViewDelegate> {
    WDBubble *_bubble;
    NSURL *_fileURL;
    
    
    // Wu:_tableView is the table of found network and the other is for file history
    IBOutlet NSTableView *_tableView;
    IBOutlet NSTableView *_historyTableView;
    
    // Wu:_checkBox is the control of enabling password
    IBOutlet NSButton *_sendText;
    IBOutlet NSButton *_sendFile;
    IBOutlet NSButton *_selectFile;
    IBOutlet NSButton *_checkBox;
    IBOutlet NSButton *_swapButton;
    
    // Wu:NSView for adding two subView and constrain their bound
    IBOutlet NSView *_superView;
   
    BOOL _isView;
    NSMutableArray *_fileHistoryArray;
   
    // Wu:The window controller : for password sheet window and preference window
    PasswordMacViewController *_passwordController;
    PreferenceViewContoller *_preferenceController;
    
    // Wu:The viewcontroller for sending files and messages
    DragFileViewController *_dragFileController;
    TextViewController *_textViewController;
    
    // Wu:Set the cumtomized cell for the tableview
    ImageAndTextCell *_imageAndTextCell;
}
// DW: for binding
@property (nonatomic, retain) NSURL *fileURL;

@end
