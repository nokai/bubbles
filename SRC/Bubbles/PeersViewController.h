//
//  PeersViewController.h
//  Bubbles
//
//  Created by 王 得希 on 12-1-9.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WDBubble.h"

@protocol PeersViewControllerDelegate
- (void)didSelectServiceName:(NSString *)serviceName;
@end

@interface PeersViewController : UITableViewController

@property (nonatomic, retain) NSString *selectedServiceName;

@property (nonatomic, retain) id<PeersViewControllerDelegate> delegate;

// DW: dimiss button is on iPhone
@property (nonatomic, retain) IBOutlet UIBarButtonItem *dismissButton;

// DW: lock button is on iPad
@property (nonatomic, retain) IBOutlet UIBarButtonItem *lockButton;

@property (nonatomic, retain) WDBubble *bubble;

@end
