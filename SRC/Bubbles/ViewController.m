//
//  ViewController.m
//  LearnBonjour
//
//  Created by 王 得希 on 12-1-5.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import "ViewController.h"
#import "PeersViewController.h"

@implementation ViewController
@synthesize bubble;
@synthesize textMessage, imageMessage, logoutButton, switchUsePassword, passwordViewController;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // DW: user defauts
    NSDictionary *t = [NSDictionary dictionaryWithObject:@"NO" forKey:kUserDefaultsUsePassword];
    [[NSUserDefaults standardUserDefaults] registerDefaults:t];
    
    self.bubble = [[WDBubble alloc] init];
    self.bubble.delegate = self;
    [self.bubble initSocket];
    
    // DW: password view
    self.passwordViewController = [[PasswordViewController alloc] initWithNibName:@"PasswordViewController" bundle:nil];
    self.passwordViewController.delegate = self;
    
    // DW: use password or not
    BOOL usePassword = [[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaultsUsePassword];
    if (usePassword) {
        [self.view addSubview:self.passwordViewController.view];
    } else {
        [self.bubble publishServiceWithPassword:@""];
        [self.bubble browseServices];
    }
    self.logoutButton.hidden = !usePassword;
    [self.switchUsePassword setOn:usePassword];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (error != nil) {
        
    } else {
        DLog(@"VC Image %@ saved.", image);
    }
}

#pragma mark - IBOultets

- (IBAction)sendText:(id)sender {
    [self.bubble broadcastMessage:[WDMessage messageWithText:textMessage.text]];
    [self.textMessage resignFirstResponder];
}

- (IBAction)selectImage:(id)sender {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        UIImagePickerController *t = [[UIImagePickerController alloc] init];
        t.delegate = self;
        [self presentModalViewController:t animated:YES];
        [t release];
    }
}

- (IBAction)saveImage:(id)sender {
    if (imageMessage.image) {
        UIImageWriteToSavedPhotosAlbum(imageMessage.image, 
                                       self, 
                                       @selector(image:didFinishSavingWithError:contextInfo:), 
                                       nil);
    }
}

- (IBAction)sendImage:(id)sender {
    [self.bubble broadcastMessage:[WDMessage messageWithImage:self.imageMessage.image]];
    [self.textMessage resignFirstResponder];
}

- (IBAction)showPeers:(id)sender {
    PeersViewController *vc = [[PeersViewController alloc] initWithNibName:@"PeersViewController" bundle:nil];
    vc.bubble = self.bubble;
    
    UINavigationController *nv = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentModalViewController:nv animated:YES];
}

- (IBAction)logout:(id)sender {
    [self.view addSubview:self.passwordViewController.view];
    [self.bubble stopService];
}

- (IBAction)triggerUsePassword:(id)sender {
    UISwitch *s = (UISwitch *)sender;
    [[NSUserDefaults standardUserDefaults] setBool:s.on forKey:kUserDefaultsUsePassword];
    self.logoutButton.hidden = !s.on;
    
    if (s.on) {
        [self logout:nil];
    } else {
        [self.bubble stopService];
        [self.bubble publishServiceWithPassword:@""];
        [self.bubble browseServices];
    }
}

#pragma mark - Events

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.textMessage resignFirstResponder];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    [self.textMessage resignFirstResponder];
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.textMessage resignFirstResponder];
    return YES;
}

#pragma mark - WDBubbleDelegate

- (void)didReceiveText:(NSString *)text {
    DLog(@"VC didReceiveText %@", text);
    self.textMessage.text = text;
}

- (void)didReceiveImage:(UIImage *)image {
    DLog(@"VC didReceiveImage %@", image);
    self.imageMessage.image = image;
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    self.imageMessage.image = image;
    
    [self dismissModalViewControllerAnimated:YES];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - PasswordViewControllerDelegate

- (void)didInputPassword:(NSString *)pwd {
    [self.bubble publishServiceWithPassword:pwd];
    [self.bubble browseServices];
}

@end
