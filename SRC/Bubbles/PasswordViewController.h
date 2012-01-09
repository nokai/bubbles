//
//  PasswordViewController.h
//  Bubbles
//
//  Created by 王 得希 on 12-1-9.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PasswordViewControllerDelegate

- (void)didInputPassword:(NSString *)pwd;

@end

@interface PasswordViewController : UIViewController <UITextFieldDelegate>

@property (nonatomic, retain) IBOutlet UITextField *password;
@property (nonatomic, retain) id<PasswordViewControllerDelegate> delegate;

@end
