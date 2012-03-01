//
//  NetworkFoundPopOverViewController.h
//  Bubbles
//
//  Created by 吴 wuziqi on 12-2-9.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WDBubble.h"
#import "TransparentTableView.h"

#define kClickCellColumn 1

@protocol NetworkFoundDelegate <NSObject>

- (void)didSelectServiceName:(NSString *)serviceName;

@end

@interface NetworkFoundPopOverViewController : NSViewController<NSTableViewDelegate,NSTableViewDataSource,NSPopoverDelegate>
{
    IBOutlet TransparentTableView *_serviceFoundTableView;
    NSPopover *_serviceFoundPopOver;
    WDBubble *_bubble;
}

@property (nonatomic , assign) WDBubble *bubble;
@property (nonatomic , retain) NSString *selectedServiceName;
@property (nonatomic , assign) id<NetworkFoundDelegate>delegate;

- (void)showServicesFoundPopOver:(NSView *)attachedView;
- (void)reloadNetwork;
@end
