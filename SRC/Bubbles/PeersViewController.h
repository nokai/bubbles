//
//  PeersViewController.h
//  Bubbles
//
//  Created by 王 得希 on 12-1-9.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PeersViewController : UITableViewController

@property (nonatomic, retain) IBOutlet UIBarButtonItem *dismissButton;

@property (nonatomic, retain) NSNetService *currentService;
@property (nonatomic, retain) NSArray *peers;

@end
