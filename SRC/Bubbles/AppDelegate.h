//
//  AppDelegate.h
//  LearnBonjour
//
//  Created by 王 得希 on 12-1-5.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ViewController;
@class WDBubble;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, retain) WDBubble *bubble;

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) ViewController *viewController;

@property (strong, nonatomic) UISplitViewController *splitViewController;

@end
