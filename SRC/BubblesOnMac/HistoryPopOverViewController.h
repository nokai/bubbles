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

@interface HistoryPopOverViewController : NSViewController<NSPopoverDelegate,NSTableViewDelegate,NSTableViewDataSource,ImageAndTextCellDelegate>
{
    IBOutlet NSTableView *_fileHistoryTableView;
    NSPopover *_historyPopOver;
    NSMutableArray *_fileHistoryArray;
    
    ImageAndTextCell *_imageAndTextCell;
}

@property (nonatomic ,retain) NSPopover *historyPopOver;
@property (nonatomic ,retain) NSMutableArray *fileHistoryArray;
@property (nonatomic ,retain) NSTableView *filehistoryTableView;

// Wu:attachedView is the the view which popover attach to like the effect in Safari
- (void)showHistoryPopOver:(NSView *)attachedView;
@end
