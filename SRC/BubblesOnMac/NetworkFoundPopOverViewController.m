//
//  NetworkFoundPopOverViewController.m
//  Bubbles
//
//  Created by 吴 wuziqi on 12-2-9.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import "NetworkFoundPopOverViewController.h"

@implementation NetworkFoundPopOverViewController
@synthesize bubble = _bubble;

#pragma mark - Private Methods

- (void)reloadNetwork
{
    [_serviceFoundTableView reloadData];   
}

- (void)showServicesFoundPopOver:(NSView *)attachedView
{
    if (_serviceFoundPopOver == nil) {
        // Wu:Create and setup our window
        _serviceFoundPopOver = [[NSPopover alloc] init];
        // Wu:The popover retains us and we retain the popover. We drop the popover whenever it is closed to avoid a cycle.
        _serviceFoundPopOver.contentViewController = self;
        _serviceFoundPopOver.behavior = NSPopoverBehaviorTransient;
        _serviceFoundPopOver.delegate = self;
    }
    // Wu:CGRectMaxXEdge means appear in the right of button
    [_serviceFoundPopOver showRelativeToRect:[attachedView bounds] ofView:attachedView preferredEdge:CGRectMaxXEdge];
}

#pragma mark - init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    
    }
    return self;
}

- (void)dealloc
{
    [_serviceFoundTableView release];
    [_serviceFoundPopOver release];
    [super dealloc];
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return _bubble.servicesFound.count;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    NSNetService *t = [_bubble.servicesFound objectAtIndex:rowIndex];
    if ([t.name isEqualToString:_bubble.service.name]) {
        return [t.name stringByAppendingString:@" (local)"];
    } else {
        return t.name;
    }
}

@end
