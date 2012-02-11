//
//  MainViewController.m
//  Bubbles
//
//  Created by 吴 wuziqi on 12-1-11.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import "MainViewController.h"
@implementation MainViewController
@synthesize fileURL = _fileURL;
@synthesize bubble = _bubble;

#pragma mark - Private Methods

/*- (void)delayNotification {
 [self performSelector:@selector(loadUserPreference) withObject:nil afterDelay:1.0f];
 }*/

// DW: we do not need this method now
/*- (void)directlySave {
 NSURL *url = [[NSUserDefaults standardUserDefaults] URLForKey:kUserDefaultMacSavingPath];
 if (_fileURL && _imageMessage.image != nil) {
 NSFileManager *manager = [NSFileManager defaultManager];
 
 NSString *fileExtension = [[_fileURL absoluteString] pathExtension];
 NSString *filename = [NSString stringWithFormat:@"%@.%@",[NSDate date],fileExtension];
 DLog(@"filename is %@!!!!!!!",filename);
 
 NSData *data = [NSData dataWithContentsOfURL:_fileURL];
 
 NSString *fullPath = [[url path] stringByAppendingPathComponent:filename];
 [manager createFileAtPath:fullPath contents:data attributes:nil];
 }
 }*/

- (void)servicesUpdated:(NSNotification *)notification {
    if (_networkPopOverController != nil) {
        [_networkPopOverController reloadNetwork];
    }
}

- (void)loadUserPreference
{
   /* if (_passwordController != nil) {
        //[[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:@"NSWindowDidBecomeKeyNotification"];
        return ;
    }
    
    bool status = [[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaultsUsePassword];
    
    if (status) {
        _passwordController = [[PasswordMacViewController alloc]init];
        _passwordController.delegate = self;
        
        [NSApp beginSheet:[_passwordController window] modalForWindow:[NSApplication sharedApplication].mainWindow modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
        
    } else {
        
    }*/
    [_bubble publishServiceWithPassword:@""];
    [_bubble browseServices];
}

- (void)storeMessage:(WDMessage *)message
{
    DLog(@"storeMessage");
    [_historyPopOverController.fileHistoryArray addObject:message];
   /* [_fileHistoryArray sortUsingComparator:^(WDMessage *obj1, WDMessage * obj2) {
        if ([obj1.time compare:obj2.time] == NSOrderedAscending)
            return NSOrderedDescending;
        else if ([obj1.time compare:obj2.time] == NSOrderedDescending)
            return NSOrderedAscending;
        else
            return NSOrderedSame;
    }];*/
    [_historyPopOverController.filehistoryTableView reloadData];
}

- (void)sendFile
{
    if (_isView == kTextViewController) {
        return ;
    }
    WDMessage *t = [[WDMessage messageWithFile:_fileURL] retain];
    [self storeMessage:t];
    [_bubble broadcastMessage:t];
    [t release];  
}

- (void)sendText
{
    DLog(@"MVC sendText %@", _textViewController.textField.stringValue);
    if (_isView == kTextViewController) {
        [_bubble broadcastMessage:[WDMessage messageWithText:_textViewController.textField.stringValue]];
    }   
}
#pragma mark - init & dealloc

- (id)init
{
    if (self = [super init]) {
        // Wu: init bubbles
        
        [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObject:@"file://localhost/~/Downloads/" forKey:kUserDefaultMacSavingPath]];
        
        _bubble = [[WDBubble alloc] init];
        _bubble.delegate = self;
        
        // Wu:Init two popover
        _historyPopOverController = [[HistoryPopOverViewController alloc]
                                     initWithNibName:@"HistoryPopOverViewController" bundle:nil];
        
        _networkPopOverController = [[NetworkFoundPopOverViewController alloc]
                                     initWithNibName:@"NetworkFoundPopOverViewController" bundle:nil];
        _networkPopOverController.bubble = _bubble;
    
        //Wu:the initilization is open the send text view;
        _isView = kTextViewController;
        
        [self loadUserPreference];
    }
    return self;
}

- (void)dealloc
{
    // Wu:Remove observe the notification
    [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:@"NSWindowDidBecomeKeyNotification"];
    
    // Wu:Remove two subviews
    [[_textViewController view] removeFromSuperview];
    [[_dragFileController view] removeFromSuperview];
    [_superView release];
    [_dragFileController release];
    [_textViewController release];
    
    // Wu:Release two window controller
    [_passwordController release];
    [_preferenceController release];
       
    [_bubble release];
    [_fileURL release];
    [_viewIndicator release];
    [_selectFileItem release];
    [_networkItem release];
    [_historyItem release];
    [super dealloc];
}

- (void)awakeFromNib
{
    // Wu:Add observer to get the notification when the main menu become key window then the sheet window will appear
    /*[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(delayNotification)
                                                 name:@"NSWindowDidBecomeKeyNotification" object:nil];*/
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(servicesUpdated:) 
                                                 name:kWDBubbleNotification
                                               object:nil];  

    // Wu: Alloc the two view controller and first add textviewcontroller into superview
    _textViewController = [[TextViewController alloc]initWithNibName:@"TextViewController" bundle:nil];
    _dragFileController = [[DragFileViewController alloc]initWithNibName:@"DragFileViewController" bundle:nil];
    
    [[_textViewController view] setFrame:[_superView bounds]];
    [[_dragFileController view] setFrame:[_superView bounds]];
    
    [_superView addSubview:[_textViewController view]];
    [_superView addSubview:[_dragFileController view]];
    
    _dragFileController.imageView.delegate = self;
    [_dragFileController.view setHidden:YES];
    
    _viewIndicator.stringValue = @"Bubbles Message";
    
}

#pragma mark - IBActions

- (IBAction)togglePassword:(id)sender {
    NSButton *button = (NSButton *)sender;
    
    DLog(@"!!!!!!!!!!!!!");
    //[[NSUserDefaults standardUserDefaults] setBool:button.state forKey:kUserDefaultsUsePassword];
    
    if (button.state == NSOnState) {
        // DW: user turned password on.
        if (_passwordController == nil) {
            _passwordController = [[PasswordMacViewController alloc]init];
            _passwordController.delegate = self;
        }
        
        // Wu: show as a sheet window to force users to set usable password
        [NSApp beginSheet:[_passwordController window] modalForWindow:[NSApplication sharedApplication].keyWindow  modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
        
    } else {
        [_bubble stopService];
        [_bubble publishServiceWithPassword:@""];
        [_bubble browseServices];
    }
}

- (IBAction)selectFile:(id)sender
{
    if (_isView == kTextViewController) {
        return ;
    }
    
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];

	[openPanel setTitle:@"Choose File"];
	[openPanel setPrompt:@"Browse"];
	[openPanel setNameFieldLabel:@"Choose a file:"];
    
    if ([openPanel runModal] == NSFileHandlingPanelOKButton) {
        _fileURL = [[openPanel URL] retain];//the path of your selected photo
        NSImage *image = [[NSImage alloc] initWithContentsOfURL:_fileURL];
        if (image != nil) {
            [_dragFileController.imageView setImage:image];
            [image release];   
        }else {
            NSImage *quicklook = [NSImage imageWithPreviewOfFileAtPath:[_fileURL path] asIcon:YES];
            [_dragFileController.imageView setImage:quicklook];
        }
    }
}

- (IBAction)showPreferencePanel:(id)sender
{
    if (_preferenceController == nil) {
        _preferenceController = [[PreferenceViewContoller alloc]init];
    }
    
    [_preferenceController showWindow:self];
}

- (IBAction)swapView:(id)sender
{
    if (_isView == kTextViewController) {
        _isView = kDragFileController;
        [_textViewController.view setHidden:YES withFade:YES];
        [_dragFileController.view setHidden:NO withFade:YES];
        _viewIndicator.stringValue = @"Bubbles File";
        
    } else {
        _isView = kTextViewController;
        [_textViewController.view setHidden:NO withFade:YES];
        [_dragFileController.view setHidden:YES withFade:YES];
         _viewIndicator.stringValue = @"Bubbles Message";
    }
}

- (IBAction)openHistoryPopOver:(id)sender
{
    NSButton *button  = (NSButton *)[_historyItem view];
    [_historyPopOverController showHistoryPopOver:button];
}

- (IBAction)openServiceFoundPopOver:(id)sender
{
    NSButton *button  = (NSButton *)[_networkItem view];
    [_networkPopOverController showServicesFoundPopOver:button];
}

- (IBAction)send:(id)sender
{
    if (_isView == kTextViewController) {
        [self sendText];
    } else {
        [self sendFile];
    }
}

#pragma mark - WDBubbleDelegate

- (void)didReceiveMessage:(WDMessage *)message ofText:(NSString *)text {
    DLog(@"VC didReceiveText %@", text);
    if (_isView == kTextViewController) {
        _textViewController.textField.stringValue = text;
        [self storeMessage:message];
    } 
}

- (void)didReceiveMessage:(WDMessage *)message ofFile:(NSURL *)url {
    DLog(@"MVC didReceiveFile %@", url);
    if (_isView != kDragFileController) {
        return ;
    }
    [self storeMessage:message];
    
    // DW: store this url for drag and drop
    if (_fileURL) {
        [_fileURL release];
    }
    _fileURL = [url retain];
   
    NSImage *image = [[NSImage alloc] initWithContentsOfURL:url];
    if (image != nil) {
        [_dragFileController.imageView setImage:image];
        [image release];
    } else {
        NSImage *quicklook = [NSImage imageWithPreviewOfFileAtPath:[url path] asIcon:YES];
        [_dragFileController.imageView setImage:quicklook];
    }
}

#pragma mark - PasswordMacViewControllerDelegate

- (void)didCancel {
   // [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kUserDefaultsUsePassword];
}

- (void)didInputPassword:(NSString *)pwd {
    [_bubble stopService];
    [_bubble publishServiceWithPassword:pwd];
    [_bubble browseServices];
}

#pragma mark - DragAndDropImageViewDelegate

- (void)dragDidFinished:(NSURL *)url
{
    DLog(@"dragDidFinished");
    if (_fileURL) {
        [_fileURL release];
    }
    _fileURL = [url retain];
}

- (NSURL *)dataDraggedToSave
{
    if (_isView == kTextViewController) {
        return nil;
    } else if (_fileURL && _dragFileController.imageView.image != nil) {
        return _fileURL;
    }
    return nil;
}

#pragma mark - NSToolBarDelegate

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
    if (theItem == _selectFileItem && _isView == kTextViewController) {
        return FALSE;
    } 
    return YES;
}


@end
