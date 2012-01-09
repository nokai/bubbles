//
//  ViewController.h
//  LearnBonjour
//
//  Created by 王 得希 on 12-1-5.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WDBubble.h"
#import "PasswordViewController.h"

#define kUserDefaultsUsePassword    @"kUserDefaultsUsePassword"

@interface ViewController : UIViewController <UITextFieldDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, PasswordViewControllerDelegate, WDBubbleDelegate>

@property (nonatomic, retain) WDBubble *bubble;

@property (nonatomic, retain) IBOutlet UITextField *textMessage;
@property (nonatomic, retain) IBOutlet UIImageView *imageMessage;
@property (nonatomic, retain) IBOutlet UIButton *logoutButton;
@property (nonatomic, retain) IBOutlet UISwitch *switchUsePassword;
@property (nonatomic, retain) PasswordViewController *passwordViewController;

@end
