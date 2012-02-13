//
//  ViewController.m
//  LearnBonjour
//
//  Created by 王 得希 on 12-1-5.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import "ViewController.h"
#import "PeersViewController.h"

#define kActionSheetButtonCopy      @"Copy"
#define kActionSheetButtonEmail     @"Email"
#define kActionSheetButtonSend      @"Resend"
#define kActionSheetButtonMessage   @"Message"
#define kActionSheetButtonPreview   @"Preview"
#define kActionSheetButtonSave      @"Save to Gallery"

#define kActionSheetButtonCancel    @"Cancel"
#define kActionSheetButtonDeleteAll @"Delete All"

@implementation ViewController
@synthesize bubble = _bubble;

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
    //[_messagesView deselectRowAtIndexPath:[_messagesView indexPathForSelectedRow] animated:YES];
}

// DW: this deletes acutal documents and their referencing messages if they have
- (void)deleteDocumentAndMessageInURL:(NSURL *)fileURL {      
    // DW: delete records in messages
    for (WDMessage *m in _messages) {
        if ([m.fileURL.path isEqualToString:fileURL.path]) {
            // DW: when we find it, we delete it and return
            
            [_messages removeObject:m];
            [[NSFileManager defaultManager] removeItemAtPath:fileURL.path
                                                       error:nil];
            
            return;
        }
    }
    
    // DW: files not in messages can also be deleted here
    [[NSFileManager defaultManager] removeItemAtPath:fileURL.path
                                               error:nil];
}

// DW: scan and delete all files
- (void)deleteAllDocuments {
    // set up Add and Edit navigation items here....
    for (NSURL *fileURL in _documents) {
        [self deleteDocumentAndMessageInURL:fileURL];
    }
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
    
    // DW: other UI
    self.navigationController.navigationBar.hidden = YES;
    _bar.topItem.rightBarButtonItem = self.editButtonItem;
    //[self setEditing:NO animated:NO];
    
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
    
    [_messagesView reloadData];
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

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {    
    [super setEditing:editing animated:animated];
    
    [_messagesView setEditing:editing animated:YES];
    if (editing) {
        [_bar.topItem setLeftBarButtonItem:_clearButton animated:YES];
    } else {
        [_bar.topItem setLeftBarButtonItem:nil animated:YES];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) || (interfaceOrientation == UIInterfaceOrientationPortrait);
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
        
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            UIPopoverController *pc = [[UIPopoverController alloc] initWithContentViewController:t];
            UIButton *b = (UIButton *)sender;
            DLog(@"VC selectFile %@", b);
            [pc presentPopoverFromRect:CGRectMake(0, 0, ((UIButton *)sender).frame.size.width, 0)
                                inView:(UIButton *)sender 
              permittedArrowDirections:UIPopoverArrowDirectionAny 
                              animated:YES];
        } else if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
            [self presentModalViewController:t animated:YES];
            [t release];
        }
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

- (IBAction)clearButton:(id)sender {
    UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:nil
                                                    delegate:self 
                                           cancelButtonTitle:kActionSheetButtonCancel
                                      destructiveButtonTitle:kActionSheetButtonDeleteAll
                                           otherButtonTitles:nil];
    [as showFromBarButtonItem:_clearButton animated:YES];
    [as release];
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
        NSString *fileExtention = [[[info valueForKey:UIImagePickerControllerReferenceURL] pathExtension] lowercaseString];
        NSData *fileData = nil;
        
        // 20120209 DW: we changed back to previous rule, store files selected from photo album to /Documents
        NSURL *storeURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", 
                                                [NSURL iOSDocumentsDirectoryURL], 
                                                fileName]];
        storeURL = [storeURL URLWithoutNameConflict];
        if ([fileExtention isEqualToString:@"jpg"]) {
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

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

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
                                otherButtonTitles:kActionSheetButtonCopy, kActionSheetButtonEmail, kActionSheetButtonSend, kActionSheetButtonMessage, nil];
    } else if (t.type == WDMessageTypeFile) {
        if ([WDMessage isImageURL:t.fileURL]) {
            as = [[UIActionSheet alloc] initWithTitle:nil
                                             delegate:self 
                                    cancelButtonTitle:kActionSheetButtonCancel
                               destructiveButtonTitle:nil
                                    otherButtonTitles:kActionSheetButtonCopy, kActionSheetButtonEmail, kActionSheetButtonSend, kActionSheetButtonPreview, kActionSheetButtonSave, nil];
        } else {
            as = [[UIActionSheet alloc] initWithTitle:nil
                                             delegate:self 
                                    cancelButtonTitle:kActionSheetButtonCancel
                               destructiveButtonTitle:nil
                                    otherButtonTitles:kActionSheetButtonEmail, kActionSheetButtonSend, kActionSheetButtonPreview, nil];
        }
    }
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        [as showFromRect:[tableView cellForRowAtIndexPath:indexPath].frame inView:_messagesView animated:YES];
    } else if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        [as showInView:self.view];
    }
    [as release];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    
    // DW: we can use here to hide bar buttons
    if (_segmentSwith.selectedSegmentIndex == 0) {
        BOOL canShowEditButton = (_messages.count > 0);
        [_bar.topItem setRightBarButtonItem:canShowEditButton?self.editButtonItem:nil];
        if (!canShowEditButton) {
            [self setEditing:NO];
        }
    } else if (_segmentSwith.selectedSegmentIndex == 1) {
        BOOL canShowEditButton = (_documents.count > 0);
        [_bar.topItem setRightBarButtonItem:(_documents.count > 0)?self.editButtonItem:nil];
        if (!canShowEditButton) {
            [self setEditing:NO];
        }
    }
    
    return _itemsToShow.count;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_segmentSwith.selectedSegmentIndex == 0) {
        [_messages removeObjectAtIndex:indexPath.row];
    } else if (_segmentSwith.selectedSegmentIndex == 1) {
        NSURL *fileURL = [_documents objectAtIndex:indexPath.row];
        [self deleteDocumentAndMessageInURL:fileURL];
        [_documents removeObjectAtIndex:indexPath.row];
    }
    
    [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath, nil] 
                     withRowAnimation:UITableViewRowAnimationFade];
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
    cell.textLabel.lineBreakMode = UILineBreakModeMiddleTruncation;
    cell.detailTextLabel.lineBreakMode = UILineBreakModeMiddleTruncation;
    
    if (_segmentSwith.selectedSegmentIndex == 0) {
        // DW: messages, AKA "History"
        
        WDMessage *t = [_itemsToShow objectAtIndex:indexPath.row];
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
            
            // DW: we use this since "image in cell" slows our app down
            if (t.fileURL) {
                UIDocumentInteractionController *interactionController = [[UIDocumentInteractionController interactionControllerWithURL:t.fileURL] retain];
                cell.imageView.image = [interactionController.icons objectAtIndex:0];
                [interactionController release];
            } else {
                cell.imageView.image = [UIImage imageNamed:@"Icon"];
            }
            
            /*
             cell.textLabel.text = [t.fileURL lastPathComponent];
             UIImage *image = [UIImage imageWithContentsOfFile:[t.fileURL path]];
             if (image) {
             cell.imageView.image = image;
             
             // DW: if it's images named like ".asset.xxx", we do not show it's name
             // 20120209 DW: we do not use "From Photos" trick, ignore this, this will never run
             if ([t.fileURL.lastPathComponent hasPrefix:@"."]) {
             cell.textLabel.text = @"From Photos";
             }
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
             */
        }
    } else if (_segmentSwith.selectedSegmentIndex == 1) {
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
    
    // DW: special actions that do not need WDMessage
    if ([buttonTitle isEqualToString:kActionSheetButtonDeleteAll]) {
        if (_segmentSwith.selectedSegmentIndex == 0) {
            [_messages removeAllObjects];
        } else if (_segmentSwith.selectedSegmentIndex == 1) {
            [self deleteAllDocuments];
            [_documents removeAllObjects];
        }
        [_messagesView reloadData];
        [self setEditing:NO animated:YES];
        return;
    }
    
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
        } else if (message.type == WDMessageTypeFile) {
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
    } else if ([buttonTitle isEqualToString:kActionSheetButtonSend]) {
        if (message.type == WDMessageTypeText) {
            WDMessage *t = [[WDMessage messageWithText:[[[NSString alloc] initWithData:message.content encoding:NSUTF8StringEncoding] autorelease]] retain];
            [self storeMessage:t];
            [_bubble broadcastMessage:t];
            [t release];
        } else if (message.type == WDMessageTypeFile) {
            WDMessage *t = [[WDMessage messageWithFile:message.fileURL] retain];
            [self storeMessage:t];
            [_bubble broadcastMessage:t];
            [t release];
        }
    }
    
    [message release];
    [_messagesView deselectRowAtIndexPath:[_messagesView indexPathForSelectedRow] animated:YES];
}

- (void)actionSheetCancel:(UIActionSheet *)actionSheet {
    DLog(@"VC actionSheetCancel");
    //[actionSheet release];
    //[_messagesView deselectRowAtIndexPath:[_messagesView indexPathForSelectedRow] animated:YES];
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
	[self dismissModalViewControllerAnimated:YES];
    //[_messagesView deselectRowAtIndexPath:[_messagesView indexPathForSelectedRow] animated:YES];
}

#pragma mark - MFMessageComposeViewControllerDelegate

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
	[self dismissModalViewControllerAnimated:YES];
    //[_messagesView deselectRowAtIndexPath:[_messagesView indexPathForSelectedRow] animated:YES];
}

#pragma mark - UIDocumentInteractionControllerDelegate

- (UIViewController *)documentInteractionControllerViewControllerForPreview: (UIDocumentInteractionController *) controller {
    return self;
}

- (void)documentInteractionControllerDidEndPreview:(UIDocumentInteractionController *)controller {
    [controller release];
    //[_messagesView deselectRowAtIndexPath:[_messagesView indexPathForSelectedRow] animated:YES];
}

#pragma mark - DirectoryWatcherDelegate

- (void)directoryDidChange:(DirectoryWatcher *)directoryWatcher {
	[_documents removeAllObjects];    // clear out the old docs and start over
    
    [_documents addObjectsFromArray:[[NSFileManager defaultManager] contentsOfDirectoryAtURL:[NSURL iOSDocumentsDirectoryURL] 
                                                                  includingPropertiesForKeys:nil 
                                                                                     options:NSDirectoryEnumerationSkipsHiddenFiles 
                                                                                       error:nil]];
    [_documents sortUsingComparator:^NSComparisonResult(NSURL *obj1, NSURL * obj2) {
        return [obj1.path.lowercaseString compare:obj2.path.lowercaseString];
    }];
    
    [_messagesView reloadData];
}

#pragma mark - UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    [popoverController release];
}

#pragma mark - Split view

- (BOOL)splitViewController:(UISplitViewController *)svc shouldHideViewController:(UIViewController *)vc inOrientation:(UIInterfaceOrientation)orientation {
    return NO;
}

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController {
    barButtonItem.title = NSLocalizedString(@"Master", @"Master");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    //self.masterPopoverController = popoverController;
    
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem {
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    //self.masterPopoverController = nil;
}

@end
