//
//  ViewController.m
//  LearnBonjour
//
//  Created by 王 得希 on 12-1-5.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import "ViewController.h"
#import "PeersViewController.h"

#define kActionSheetButtonMessage   @"Message"
#define kActionSheetButtonEmail     @"Email"
#define kActionSheetButtonPrint     @"Print"
#define kActionSheetButtonCopy      @"Copy"
#define kActionSheetButtonSave      @"Save to Gallery"
#define kActionSheetButtonOpenIn    @"Open In.."
#define kActionSheetButtonCancel    @"Cancel"

@implementation ViewController

- (void)refreshLockStatus {
    BOOL usePassword = [[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaultsUsePassword];
    if (usePassword) {
        [_lockButton setImage:[UIImage imageNamed:@"lock_on"] forState:UIControlStateNormal];
    } else {
        [_lockButton setImage:[UIImage imageNamed:@"lock_off"] forState:UIControlStateNormal];
    }
}

- (void)lock {
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Lock Bubbles" 
                                                 message:@"Please input password:"
                                                delegate:self 
                                       cancelButtonTitle:@"Cancel" 
                                       otherButtonTitles:@"OK", nil];
    av.alertViewStyle = UIAlertViewStyleSecureTextInput;
    [av show];
    [av release];
}

- (void)storeMessage:(WDMessage *)message {
    [_messages addObject:message];
    [_messages sortUsingComparator:^(WDMessage *obj1, WDMessage * obj2) {
        if ([obj1.time compare:obj2.time] == NSOrderedAscending)
            return NSOrderedDescending;
        else if ([obj1.time compare:obj2.time] == NSOrderedDescending)
            return NSOrderedAscending;
        else
            return NSOrderedSame;
    }];
    [_messagesView reloadData];
}

- (void)displayMailComposerSheetWithMessage:(WDMessage *)message {
	MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
    if (!picker) {
        return;
    }
    
	picker.mailComposeDelegate = self;
    
    UILabel *label = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont boldSystemFontOfSize:20.0];
    label.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    label.textAlignment = UITextAlignmentCenter;
    label.textColor = [UIColor colorWithWhite:0.5 alpha:1];
    picker.navigationItem.titleView = label;
    label.text = NSLocalizedString(@"Peers", @"");
    [label sizeToFit];
    if ([picker.navigationBar respondsToSelector:@selector(setBackgroundImage:forBarMetrics:)]) {
        [picker.navigationBar setBackgroundImage:[UIImage imageNamed:@"tile_bg"]
                                   forBarMetrics:UIBarMetricsDefault];
    }
    
	// Set up recipients
    if (message.type == WDMessageTypeText) {
        NSString *emailBody = [[NSString alloc] initWithData:message.content encoding:NSUTF8StringEncoding];
        [picker setMessageBody:emailBody isHTML:YES];
    } else {
        NSData *myData = [NSData dataWithContentsOfFile:message.fileURL.path];
        [picker addAttachmentData:myData mimeType:@"image/jpeg" fileName:@"attachment"];
	}
    
	[self presentModalViewController:picker animated:YES];
	[picker release];
}

- (void)displayMessageComposerSheetWithMessage:(WDMessage *)message {
    MFMessageComposeViewController *picker = [[MFMessageComposeViewController alloc] init];
    if ((!picker)||(![MFMessageComposeViewController canSendText])) {
        return;
    }
    
    picker.messageComposeDelegate = self;
    picker.body = [[NSString alloc] initWithData:message.content encoding:NSUTF8StringEncoding];
	[self presentModalViewController:picker animated:YES];
	[picker release];
}

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
    
    // DW: bubble
    _bubble = [[WDBubble alloc] init];
    _bubble.delegate = self;
    
    // DW: messages
    _messages = [[NSMutableArray alloc] init];
    
    // DW: password view
    _passwordViewController = [[PasswordViewController alloc] initWithNibName:@"PasswordViewController" bundle:nil];
    _passwordViewController.delegate = self;
    
    // DW: use password or not
    BOOL usePassword = [[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaultsUsePassword];
    if (usePassword) {
        [self lock];
    } else {
        [_bubble publishServiceWithPassword:@""];
        [_bubble browseServices];
    }
    [self refreshLockStatus];
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
    TextViewController *vc = [[TextViewController alloc] initWithNibName:@"TextViewController" bundle:nil];
    vc.delegate = self;
    
    UINavigationController *nv = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentModalViewController:nv animated:YES];
    
    [vc release];
    [nv release];
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

/*
 - (IBAction)saveImage:(id)sender {
 if (_imageMessage.image) {
 UIImageWriteToSavedPhotosAlbum(_imageMessage.image, 
 self, 
 @selector(image:didFinishSavingWithError:contextInfo:), 
 nil);
 }
 }
 */

// DW: can only send images and movies for now.
- (void)sendFile {
    if (_fileURL) {
        // DW: a movie or JPG or PNG        
        WDMessage *t = [[WDMessage messageWithFile:_fileURL] retain];
        [self storeMessage:t];
        [_bubble broadcastMessage:t];
        [t release];
    } else {
        DLog(@"VC sendFile no good file URL");
    }
}

- (IBAction)showPeers:(id)sender {
    PeersViewController *vc = [[PeersViewController alloc] initWithNibName:@"PeersViewController" bundle:nil];
    vc.bubble = _bubble;
    
    UINavigationController *nv = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentModalViewController:nv animated:YES];
    
    [vc release];
    [nv release];
}

- (IBAction)toggleUsePassword:(id)sender {
    BOOL usePassword = [[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaultsUsePassword];
    usePassword = !usePassword;
    [[NSUserDefaults standardUserDefaults] setBool:usePassword forKey:kUserDefaultsUsePassword];
    [self refreshLockStatus];
    
    if (usePassword) {
        [self lock];
    } else {
        [_bubble stopService];
        [_bubble publishServiceWithPassword:@""];
        [_bubble browseServices];
    }
}

#pragma mark - WDBubbleDelegate

- (void)didReceiveMessage:(WDMessage *)message ofText:(NSString *)text {
    DLog(@"VC didReceiveText %@", text);
    //_textMessage.text = text;
    [self storeMessage:message];
}

- (void)didReceiveMessage:(WDMessage *)message ofFile:(NSURL *)url {
    // DW: change original file URL to local one
    message.fileURL = url;
    [self storeMessage:message];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    DLog(@"VC didFinishPickingMediaWithInfo %@", info);
    if (_fileURL) {
        [_fileURL release];
        _fileURL = nil;
    }
    
    NSString *mediaType = [info valueForKey:UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:@"public.image"]) {
        UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
        NSString *fileName = [[info valueForKey:UIImagePickerControllerReferenceURL] lastPathComponent];
        //fileName = [NSString stringWithFormat:@".%@", fileName];
        NSString *fileExtention = [[info valueForKey:UIImagePickerControllerReferenceURL] pathExtension];
        NSData *fileData = nil;
        NSURL *storeURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", 
                                                [NSURL iOSDocumentsDirectoryURL], 
                                                fileName]];
        storeURL = [NSURL URLWithSmartConvertionFromURL:storeURL];
        if ([fileExtention isEqualToString:@"JPG"]) {
            fileData = UIImageJPEGRepresentation(image, 1.0);
            [fileData writeToURL:storeURL atomically:YES];
            _fileURL = [storeURL retain];
        } else {
            DLog(@"VC didFinishPickingMediaWithInfo %@ not PNG or JPG", fileExtention);
            fileData = UIImagePNGRepresentation(image);
            [fileData writeToURL:storeURL atomically:YES];
            _fileURL = [storeURL retain];
        }
        DLog(@"VC didFinishPickingMediaWithInfo URL is %@", _fileURL);
        [self sendFile];
    } else if ([mediaType isEqualToString:@"public.movie"]) {
        _fileURL = [[info valueForKey:UIImagePickerControllerMediaURL] retain];
        DLog(@"VC didFinishPickingMediaWithInfo select %@", _fileURL);
        [self sendFile];
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

#pragma mark - TextViewControllerDelegate

- (void)didFinishWithText:(NSString *)text {
    WDMessage *t = [[WDMessage messageWithText:text] retain];
    [self storeMessage:t];
    [_bubble broadcastMessage:t];
    [t release];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    DLog(@"VC clickedButtonAtIndex %i", buttonIndex);
    if (buttonIndex == 0) {
        // DW: user canceled
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kUserDefaultsUsePassword];
        [self refreshLockStatus];
    } else if (buttonIndex == 1) {
        [_bubble stopService];
        [_bubble publishServiceWithPassword:[alertView textFieldAtIndex:0].text];
        [_bubble browseServices];
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    UIActionSheet *as = nil;
    
    // DW: add action sheet buttons
    WDMessage *t = [[_messages objectAtIndex:indexPath.row] retain];
    if (t.type == WDMessageTypeText) {
        as = [[UIActionSheet alloc] initWithTitle:nil
                                         delegate:self 
                                cancelButtonTitle:kActionSheetButtonCancel
                           destructiveButtonTitle:nil
                                otherButtonTitles:kActionSheetButtonCopy, kActionSheetButtonMessage, kActionSheetButtonEmail, kActionSheetButtonPrint, nil];
    } else if (t.type == WDMessageTypeFile) {
        if ([WDMessage isImageURL:t.fileURL]) {
            as = [[UIActionSheet alloc] initWithTitle:nil
                                             delegate:self 
                                    cancelButtonTitle:kActionSheetButtonCancel
                               destructiveButtonTitle:nil
                                    otherButtonTitles:kActionSheetButtonCopy, kActionSheetButtonSave, kActionSheetButtonPrint, kActionSheetButtonEmail, nil];
        } else {
            as = [[UIActionSheet alloc] initWithTitle:nil
                                             delegate:self 
                                    cancelButtonTitle:kActionSheetButtonCancel
                               destructiveButtonTitle:nil
                                    otherButtonTitles:kActionSheetButtonEmail, kActionSheetButtonOpenIn, nil];
        }
    }
    [t release];
    
    
    [as showInView:self.view];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return _messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell...
    WDMessage *t = [[_messages objectAtIndex:indexPath.row] retain];
    cell.detailTextLabel.lineBreakMode = UILineBreakModeMiddleTruncation;
    cell.detailTextLabel.text = t.sender;
    if (t.type == WDMessageTypeText) {
        DLog(@"VC cellForRowAtIndexPath t is %@", t);
        cell.textLabel.text = [[[NSString alloc] initWithData:t.content encoding:NSUTF8StringEncoding] autorelease];
        cell.imageView.image = nil;
    } else if (t.type == WDMessageTypeFile) {
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        df.dateFormat = @"hh:mm:ss";
        cell.textLabel.text = [df stringFromDate:t.time];
        UIImage *image = [UIImage imageWithContentsOfFile:[t.fileURL path]];
        if (image) {
            cell.imageView.image = image;
        } else {
            cell.imageView.image = [UIImage imageNamed:@"Icon"];
        }
        [df release];
    }
    [t release];
    
    return cell;
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    WDMessage *message = [_messages objectAtIndex:[_messagesView indexPathForSelectedRow].row];
    [_messagesView deselectRowAtIndexPath:[_messagesView indexPathForSelectedRow] animated:YES];
    
    NSString *buttonTitle = [[actionSheet buttonTitleAtIndex:buttonIndex] retain];
    [actionSheet release];
    
    if ([buttonTitle isEqualToString:kActionSheetButtonEmail]) {
        [self displayMailComposerSheetWithMessage:message];
    } else if ([buttonTitle isEqualToString:kActionSheetButtonMessage]) {
        [self displayMessageComposerSheetWithMessage:message];
    } else if ([buttonTitle isEqualToString:kActionSheetButtonCopy]) {
        if (message.type == WDMessageTypeText) {
            [UIPasteboard generalPasteboard].string = [[NSString alloc] initWithData:message.content encoding:NSUTF8StringEncoding];
        } else {
            [UIPasteboard generalPasteboard].image = [UIImage imageWithContentsOfFile:message.fileURL.path];
        }
    }
}

- (void)actionSheetCancel:(UIActionSheet *)actionSheet {
    DLog(@"VC actionSheetCancel");
    [actionSheet release];
    [_messagesView deselectRowAtIndexPath:[_messagesView indexPathForSelectedRow] animated:YES];
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark - MFMessageComposeViewControllerDelegate

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
	[self dismissModalViewControllerAnimated:YES];
}

@end
