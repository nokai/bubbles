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
#define kActionSheetButtonCopy      @"Copy"
#define kActionSheetButtonSave      @"Save to Gallery"
#define kActionSheetButtonPreview   @"Preview"
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
    
	// Set up recipients
    if (message.type == WDMessageTypeText) {
        NSString *emailBody = [[[NSString alloc] initWithData:message.content encoding:NSUTF8StringEncoding] autorelease];
        [picker setMessageBody:emailBody isHTML:YES];
    } else {
        NSData *myData = [NSData dataWithContentsOfFile:message.fileURL.path];
        NSURLRequest *req = [NSURLRequest requestWithURL:message.fileURL];
        NSURLResponse *res = nil;
        [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:nil];
        DLog(@"VC displayMailComposerSheetWithMessage UTI %@", [res MIMEType]);
        [picker addAttachmentData:myData mimeType:@"image/jpeg" fileName:@"attachment"];
	}
    
	[self presentModalViewController:picker animated:YES];
	[picker release];
}

- (void)displayMessageComposerSheetWithMessage:(WDMessage *)message {
    if (![MFMessageComposeViewController canSendText]) {
        return;
    }
    
    MFMessageComposeViewController *picker = [[MFMessageComposeViewController alloc] init];
    if (!picker) {
        return;
    }
    
    picker.messageComposeDelegate = self;
    picker.body = [[[NSString alloc] initWithData:message.content encoding:NSUTF8StringEncoding] autorelease];
	[self presentModalViewController:picker animated:YES];
	[picker release];
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (error != nil) {
        
    } else {
        DLog(@"VC Image %@ saved.", image);
    }
    [_messagesView deselectRowAtIndexPath:[_messagesView indexPathForSelectedRow] animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc {
    [_bubble release];
    [_messages release];
    [_documents release];
    [_directoryWatcher release];
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
    
    // DW: messages or files
    _messages = [[NSMutableArray alloc] init];
    _directoryWatcher = [[DirectoryWatcher watchFolderWithPath:[NSURL iOSDocumentsDirectoryPath] delegate:self] retain];
    _documents = [[NSMutableArray alloc] init];
    [self directoryDidChange:_directoryWatcher];
    if (_segmentSwith.selectedSegmentIndex == 0) {
        _itemsToShow = _messages;
    } else {
        _itemsToShow = _documents;
    }
    
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

#pragma mark - IBOultets

- (IBAction)sendText:(id)sender {
    TextViewController *vc = [[TextViewController alloc] initWithNibName:@"TextViewController" bundle:nil];
    vc.delegate = self;
    
    UINavigationController *nv = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentModalViewController:nv animated:YES];
    
    [vc release];
    [nv release];
}

- (IBAction)selectFile:(id)sender {
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

- (IBAction)toggleView:(id)sender {
    UISegmentedControl *sc = (UISegmentedControl *)sender;
    if (sc.selectedSegmentIndex == 0) {
        _itemsToShow = _messages;
    } else if (sc.selectedSegmentIndex == 1) {
        _itemsToShow = _documents;
    }
    [_messagesView reloadData];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    WDMessage *t = nil;
    UIActionSheet *as = nil;
    
    // DW: construct a WDMessage
    if (_segmentSwith.selectedSegmentIndex == 0) {
        t = [_messages objectAtIndex:indexPath.row];
    } else if (_segmentSwith.selectedSegmentIndex == 1) {
        NSURL *fileURL = [_documents objectAtIndex:indexPath.row];
        t = [[[WDMessage alloc] init] autorelease];
        t.type = WDMessageTypeFile;
        t.fileURL = fileURL;
    }
    
    // DW: chose an action
    if (t.type == WDMessageTypeText) {
        as = [[UIActionSheet alloc] initWithTitle:nil
                                         delegate:self 
                                cancelButtonTitle:kActionSheetButtonCancel
                           destructiveButtonTitle:nil
                                otherButtonTitles:kActionSheetButtonCopy, kActionSheetButtonMessage, kActionSheetButtonEmail, nil];
    } else if (t.type == WDMessageTypeFile) {
        if ([WDMessage isImageURL:t.fileURL]) {
            as = [[UIActionSheet alloc] initWithTitle:nil
                                             delegate:self 
                                    cancelButtonTitle:kActionSheetButtonCancel
                               destructiveButtonTitle:nil
                                    otherButtonTitles:kActionSheetButtonCopy, kActionSheetButtonEmail, kActionSheetButtonPreview, kActionSheetButtonSave, nil];
        } else {
            as = [[UIActionSheet alloc] initWithTitle:nil
                                             delegate:self 
                                    cancelButtonTitle:kActionSheetButtonCancel
                               destructiveButtonTitle:nil
                                    otherButtonTitles:kActionSheetButtonEmail, kActionSheetButtonPreview, nil];
        }
    }
    [as showInView:self.view];
    [as release];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return _itemsToShow.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
        UILongPressGestureRecognizer *longPressGesture = [[[UILongPressGestureRecognizer alloc] initWithTarget:self 
                                                                                                        action:@selector(longPress:)] autorelease];
		[cell addGestureRecognizer:longPressGesture];
    }
    
    // Configure the cell...
    if (_segmentSwith.selectedSegmentIndex == 0) {
        // DW: messages, AKA "History"
        
        WDMessage *t = [_itemsToShow objectAtIndex:indexPath.row];
        cell.textLabel.lineBreakMode = UILineBreakModeMiddleTruncation;
        cell.detailTextLabel.lineBreakMode = UILineBreakModeMiddleTruncation;
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        df.dateFormat = @"hh:mm:ss";
        cell.detailTextLabel.text = [t.sender stringByAppendingFormat:@" %@", [df stringFromDate:t.time]];
        [df release];
        if (t.type == WDMessageTypeText) {
            DLog(@"VC cellForRowAtIndexPath t is %@", t);
            cell.textLabel.text = [[[NSString alloc] initWithData:t.content encoding:NSUTF8StringEncoding] autorelease];
            cell.imageView.image = [UIImage imageNamed:@"Icon-Text"];
        } else if (t.type == WDMessageTypeFile) {
            cell.textLabel.text = [t.fileURL lastPathComponent];
            UIImage *image = [UIImage imageWithContentsOfFile:[t.fileURL path]];
            if (image) {
                cell.imageView.image = image;
            } else {
                //cell.imageView.image = [UIImage imageNamed:@"Icon"];
                if (t.fileURL) {
                    UIDocumentInteractionController *interactionController = [[UIDocumentInteractionController interactionControllerWithURL:t.fileURL] retain];
                    cell.imageView.image = [interactionController.icons objectAtIndex:0];
                    [interactionController release];
                } else {
                    cell.imageView.image = [UIImage imageNamed:@"Icon"];
                }
            }
        }
    } else {
        NSURL *fileURL = [_documents objectAtIndex:indexPath.row];
        
        UIDocumentInteractionController *interactionController = [[UIDocumentInteractionController interactionControllerWithURL:fileURL] retain];
        
        // layout the cell
        cell.textLabel.text = [[fileURL path] lastPathComponent];
        UIImage *image = [UIImage imageWithContentsOfFile:fileURL.path];
        if (image) {
            cell.imageView.image = image;
        } else {
            cell.imageView.image = [interactionController.icons objectAtIndex:0];
        }
        
        // DW: size info in detail label
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:interactionController.URL.path error:nil];
        NSInteger fileSize = [[fileAttributes objectForKey:NSFileSize] intValue];
        
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@",
                                     [NSURL formattedFileSize:fileSize], interactionController.UTI];
        [interactionController release];
    }
    
    return cell;
}

// DW: we recognize long press since we hope to show full name of a file without any dots
- (void)longPress:(UILongPressGestureRecognizer *)gesture {
	// only when gesture was recognized, not when ended
	if (gesture.state == UIGestureRecognizerStateBegan) {
		// get affected cell
		UITableViewCell *cell = (UITableViewCell *)[gesture view];
        
		// get indexPath of cell
		NSIndexPath *indexPath = [_messagesView indexPathForCell:cell];
        
		// do something with this action
		NSLog(@"Long-pressed cell at row %@", indexPath);
	}
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    // DW: construct a WDMessage
    WDMessage *message = nil;
    if (_segmentSwith.selectedSegmentIndex == 0) {
        // DW: messages
        message = [[_messages objectAtIndex:[_messagesView indexPathForSelectedRow].row] retain];
    } else if (_segmentSwith.selectedSegmentIndex == 1) {
        NSURL *fileURL = [_documents objectAtIndex:_messagesView.indexPathForSelectedRow.row];
        message = [[WDMessage alloc] init];
        message.type = WDMessageTypeFile;
        message.fileURL = fileURL;
    }
    
    // DW: chose an action
    if ([buttonTitle isEqualToString:kActionSheetButtonEmail]) {
        [self displayMailComposerSheetWithMessage:message];
    } else if ([buttonTitle isEqualToString:kActionSheetButtonMessage]) {
        [self displayMessageComposerSheetWithMessage:message];
    } else if ([buttonTitle isEqualToString:kActionSheetButtonCopy]) {
        if (message.type == WDMessageTypeText) {
            [UIPasteboard generalPasteboard].string = [[[NSString alloc] initWithData:message.content encoding:NSUTF8StringEncoding] autorelease];
        } else {
            [UIPasteboard generalPasteboard].image = [UIImage imageWithContentsOfFile:message.fileURL.path];
        }
    } else if ([buttonTitle isEqualToString:kActionSheetButtonPreview]) {
        UIDocumentInteractionController *interactionController = [[UIDocumentInteractionController interactionControllerWithURL:message.fileURL] retain];
        interactionController.delegate = self;
        DLog(@"VC clickedButtonAtIndex present %i", [interactionController presentPreviewAnimated:YES]);
    } else if ([buttonTitle isEqualToString:kActionSheetButtonSave]) {
        UIImage *image = [UIImage imageWithContentsOfFile:message.fileURL.path];
        if (image) {
            UIImageWriteToSavedPhotosAlbum(image, 
                                           self, 
                                           @selector(image:didFinishSavingWithError:contextInfo:), 
                                           nil);
        }
    } else if ([buttonTitle isEqualToString:kActionSheetButtonCancel]) {
        [_messagesView deselectRowAtIndexPath:[_messagesView indexPathForSelectedRow] animated:YES];
    }
    
    [message release];
}

- (void)actionSheetCancel:(UIActionSheet *)actionSheet {
    DLog(@"VC actionSheetCancel");
    //[actionSheet release];
    [_messagesView deselectRowAtIndexPath:[_messagesView indexPathForSelectedRow] animated:YES];
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
	[self dismissModalViewControllerAnimated:YES];
    [_messagesView deselectRowAtIndexPath:[_messagesView indexPathForSelectedRow] animated:YES];
}

#pragma mark - MFMessageComposeViewControllerDelegate

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
	[self dismissModalViewControllerAnimated:YES];
    [_messagesView deselectRowAtIndexPath:[_messagesView indexPathForSelectedRow] animated:YES];
}

#pragma mark - UIDocumentInteractionControllerDelegate

- (UIViewController *)documentInteractionControllerViewControllerForPreview: (UIDocumentInteractionController *) controller {
    return self;
}

- (void)documentInteractionControllerDidEndPreview:(UIDocumentInteractionController *)controller {
    [controller release];
    [_messagesView deselectRowAtIndexPath:[_messagesView indexPathForSelectedRow] animated:YES];
}

#pragma mark - DirectoryWatcherDelegate

- (void)directoryDidChange:(DirectoryWatcher *)directoryWatcher {
	[_documents removeAllObjects];    // clear out the old docs and start over
	
	NSString *documentsDirectoryPath = [NSURL iOSDocumentsDirectoryPath];
	NSArray *documentsDirectoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectoryPath error:NULL];
    
	for (NSString* curFileName in [documentsDirectoryContents objectEnumerator]) {
		NSString *filePath = [documentsDirectoryPath stringByAppendingPathComponent:curFileName];
		NSURL *fileURL = [NSURL fileURLWithPath:filePath];
		
		BOOL isDirectory;
        [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory];
		
        // proceed to add the document URL to our list (ignore the "Inbox" folder)
        if (!(isDirectory && [curFileName isEqualToString: @"Inbox"])) {
            [_documents addObject:fileURL];
        }
	}
	
	[_messagesView reloadData];
}

@end
