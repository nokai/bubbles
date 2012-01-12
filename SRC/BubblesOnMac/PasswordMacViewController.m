//
//  PasswordViewController.m
//  Bubbles
//
//  Created by 吴 wuziqi on 12-1-11.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import "PasswordMacViewController.h"

@implementation PasswordMacViewController

@synthesize textField = _textField;
@synthesize okButton = _okButton;
@synthesize resetButton = _resetButton;
@synthesize delegate;

- (id)init
{
    if (![super initWithWindowNibName:@"PasswordWindowView"])
            return nil;
    return self;
}

- (void)dealloc
{
    [_textField release];
    [_okButton release];
    [_resetButton release];
    [super dealloc];
}

#pragma mark - 
#pragma mark IBAction

- (IBAction)confirmPassword:(id)sender
{
    if ([_textField.stringValue length] != 0) {
        [self.delegate didInputPassword:_textField.stringValue];
    }
    else
    {
        DLog(@"The length of password can not be 0");
    }
}

- (IBAction)resetPassword:(id)sender
{
    _textField.stringValue = @"";
}

@end