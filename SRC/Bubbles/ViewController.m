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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc {
    [_bubble release];
    [_passwordViewController release];
    
    [super release];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // DW: user defauts
    NSDictionary *t = [NSDictionary dictionaryWithObject:@"NO" forKey:kUserDefaultsUsePassword];
    [[NSUserDefaults standardUserDefaults] registerDefaults:t];
    
    _bubble = [[WDBubble alloc] init];
    _bubble.delegate = self;
    
    // DW: password view
    _passwordViewController = [[PasswordViewController alloc] initWithNibName:@"PasswordViewController" bundle:nil];
    _passwordViewController.delegate = self;
    
    // DW: use password or not
    BOOL usePassword = [[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaultsUsePassword];
    if (usePassword) {
        [self.view addSubview:_passwordViewController.view];
    } else {
        [_bubble publishServiceWithPassword:@""];
        [_bubble browseServices];
    }
    _logoutButton.hidden = !usePassword;
    [_switchUsePassword setOn:usePassword];
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
    [_bubble broadcastMessage:[WDMessage messageWithText:_textMessage.text]];
    [_textMessage resignFirstResponder];
}

- (IBAction)selectImage:(id)sender {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        UIImagePickerController *t = [[UIImagePickerController alloc] init];
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            t.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
        }
        t.delegate = self;
        [self presentModalViewController:t animated:YES];
        [t release];
    }
}

- (IBAction)saveImage:(id)sender {
    if (_imageMessage.image) {
        UIImageWriteToSavedPhotosAlbum(_imageMessage.image, 
                                       self, 
                                       @selector(image:didFinishSavingWithError:contextInfo:), 
                                       nil);
    }
}

- (IBAction)sendImage:(id)sender {
    [_bubble broadcastMessage:[WDMessage messageWithImage:_imageMessage.image]];
    [_textMessage resignFirstResponder];
}

- (IBAction)showPeers:(id)sender {
    PeersViewController *vc = [[PeersViewController alloc] initWithNibName:@"PeersViewController" bundle:nil];
    vc.bubble = _bubble;
    
    UINavigationController *nv = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentModalViewController:nv animated:YES];
}

- (IBAction)logout:(id)sender {
    [self.view addSubview:_passwordViewController.view];
    [_bubble stopService];
}

- (IBAction)triggerUsePassword:(id)sender {
    UISwitch *s = (UISwitch *)sender;
    [[NSUserDefaults standardUserDefaults] setBool:s.on forKey:kUserDefaultsUsePassword];
    _logoutButton.hidden = !s.on;
    
    if (s.on) {
        [self logout:nil];
    } else {
        [_bubble stopService];
        [_bubble publishServiceWithPassword:@""];
        [_bubble browseServices];
    }
}

#pragma mark - Events

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [_textMessage resignFirstResponder];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    [_textMessage resignFirstResponder];
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [_textMessage resignFirstResponder];
    return YES;
}

#pragma mark - WDBubbleDelegate

- (void)didReceiveText:(NSString *)text {
    DLog(@"VC didReceiveText %@", text);
    _textMessage.text = text;
}

- (void)didReceiveImage:(UIImage *)image {
    DLog(@"VC didReceiveImage %@", image);
    _imageMessage.image = image;
}

- (void)didReceiveFile:(NSURL *)url {
    
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    DLog(@"VC didFinishPickingMediaWithInfo %@", info);
    if (_fileURL) {
        [_fileURL release];
    }
    
    NSString *mediaType = [info valueForKey:UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:@"public.image"]) {
        UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
        NSString *fileName = [[info valueForKey:UIImagePickerControllerReferenceURL] lastPathComponent];
        NSString *fileExtention = [[info valueForKey:UIImagePickerControllerReferenceURL] pathExtension];
        NSData *fileData = nil;
        NSURL *storeURL = [NSURL URLWithString:fileName relativeToURL:[UIDocument applicationDocumentsDirectory]];
        if ([fileExtention isEqualToString:@"PNG"]) {
            fileData = UIImagePNGRepresentation(image);
            [fileData writeToURL:storeURL atomically:YES];
        } else if ([fileExtention isEqualToString:@"JPG"]) {
            fileData = UIImageJPEGRepresentation(image, 1.0);
            [fileData writeToURL:storeURL atomically:YES];
        } else {
            DLog(@"VC didFinishPickingMediaWithInfo %@ not PNG or JPG", fileExtention);
        }
        _imageMessage.image = image;
    } else if ([mediaType isEqualToString:@"public.movie"]) {
        _imageMessage.image = [UIImage imageNamed:@"Icon.png"];
        _fileURL = [[info valueForKey:UIImagePickerControllerMediaURL] retain];
        DLog(@"VC didFinishPickingMediaWithInfo select %@", _fileURL);
    } else {
        _fileURL = nil;
    }
    [self dismissModalViewControllerAnimated:YES];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - PasswordViewControllerDelegate

- (void)didInputPassword:(NSString *)pwd {
    [_bubble publishServiceWithPassword:pwd];
    [_bubble browseServices];
}

@end
