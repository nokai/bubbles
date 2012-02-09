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
#import "NSView+NSView_Fade_.h"
#import "HistoryPopOverViewController.h"
#import "NetworkFoundPopOverViewController.h"

#define kTextViewController 0
#define kDragFileController 1

@interface MainViewController : NSObject <WDBubbleDelegate,PasswordMacViewControllerDelegate,DragAndDropImageViewDelegate,NSToolbarDelegate> {
    WDBubble *_bubble;
    NSURL *_fileURL;
        
    // Wu:_checkBox is the control of enabling password
    IBOutlet NSButton *_checkBox;
    IBOutlet NSButton *_swapButton;
    
    // Wu:NSView for adding two subView and constrain their bound
    IBOutlet NSView *_superView;
    
    IBOutlet NSToolbarItem *_selectFileItem;
    IBOutlet NSToolbarItem *_networkItem;
    IBOutlet NSToolbarItem *_historyItem;
    
    BOOL _isView;
       
    // Wu:The window controller : for password sheet window and preference window
    PasswordMacViewController *_passwordController;
    PreferenceViewContoller *_preferenceController;
    
    // Wu:The viewcontroller for sending files and messages
    DragFileViewController *_dragFileController;
    TextViewController *_textViewController;
    
    // Wu:Two Popover 
    HistoryPopOverViewController *_historyPopOverController;
    NetworkFoundPopOverViewController *_networkPopOverController;
}
// DW: for binding
@property (nonatomic, retain) NSURL *fileURL;
@property (nonatomic, assign) WDBubble *bubble;
@end
