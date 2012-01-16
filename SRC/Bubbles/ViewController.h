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

@interface ViewController : UIViewController <UITextFieldDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, PasswordViewControllerDelegate, WDBubbleDelegate> {
    WDBubble *_bubble;
    
    // DW: UI
    IBOutlet UITextField *_textMessage;
    IBOutlet UIImageView *_imageMessage;
    IBOutlet UIButton *_logoutButton;
    IBOutlet UISwitch *_switchUsePassword;
    
    // DW: password
    PasswordViewController *_passwordViewController;
}

@end
