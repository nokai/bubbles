//
//  PasswordViewController.m
//  Bubbles
//
//  Created by 王 得希 on 12-1-9.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import "PasswordViewController.h"

@implementation PasswordViewController
@synthesize password, delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Events

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.password resignFirstResponder];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
	[self.password resignFirstResponder];
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[self.password resignFirstResponder];
    return YES;
}

#pragma mark - IBOutlets

- (IBAction)go:(id)sender {
    [self.delegate didInputPassword:self.password.text];
    self.password.text = @"";
    [self.view removeFromSuperview];
}

@end
