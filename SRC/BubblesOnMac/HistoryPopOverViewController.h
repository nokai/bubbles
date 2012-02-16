//
//  HistoryPopOverViewController.h
//  Bubbles
//
//  Created by 吴 wuziqi on 12-2-9.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WDMessage.h"
#import "ImageAndTextCell.h"
#import "NSImage+QuickLook.h"
#import "AppDelegate.h"
#import "TransparentTableView.h"
#import "NSTableView+ContextMenu.h"

@interface HistoryPopOverViewController : NSViewController<NSPopoverDelegate,NSTableViewDataSource,NSTableViewDelegate,ImageAndTextCellDelegate,ContextMenuDelegate>
{
    IBOutlet TransparentTableView *_fileHistoryTableView;
    NSPopover *_historyPopOver;
    NSMutableArray *_fileHistoryArray;
    
    ImageAndTextCell *_imageAndTextCell;
    
    IBOutlet NSButton *_removeButton;
}

@property (nonatomic ,retain) NSPopover *historyPopOver;
@property (nonatomic ,retain) NSMutableArray *fileHistoryArray;
@property (nonatomic ,retain) TransparentTableView *filehistoryTableView;

// Wu:attachedView is the the view which popover attach to like the effect in Safari
- (void)showHistoryPopOver:(NSView *)attachedView;

@end
