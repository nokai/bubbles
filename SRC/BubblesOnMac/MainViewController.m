//
//  MainViewController.m
//  Bubbles
//
//  Created by 吴 wuziqi on 12-1-11.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import "MainViewController.h"

#define kButtonTitleSendText    @"Text"
#define kButtonTitleSendFile    @"File"
#define kTooBarIndexOfSelectButton    2

@implementation MainViewController
@synthesize fileURL = _fileURL;
@synthesize bubble = _bubble;

#pragma mark - Private Methods


- (void)firstUse
{
    NSInteger firstUser = [[NSUserDefaults standardUserDefaults] integerForKey:kFirstUseKey];
    if (firstUser == 0) {
        _featureController = [[FeatureWindowController alloc]init];
        [_featureController showWindow:self];
    }
    
    [[NSUserDefaults standardUserDefaults] setInteger:++firstUser forKey:kFirstUseKey];
}
// Wu: NO for can not send, YES for will send
- (BOOL)sendToSelectedServiceOfMessage:(WDMessage *)message {
    if (!_selectedServiceName || [_selectedServiceName isEqualToString:@""]) {
        return NO;
    }
    
    [_bubble sendMessage:message toServiceNamed:_selectedServiceName];
    return YES;
}

- (void)servicesUpdated:(NSNotification *)notification {
  
    DLog(@"bubbles count is %d",_bubble.servicesFound.count);
    if (_bubble.servicesFound.count > 1) {
        // DW: if we already have one service selected, we do not update the selection now
        if (_selectedServiceName) {
            return;
        }
        
        for (NSNetService *s in _bubble.servicesFound) {
            if ([_bubble isDifferentService:s]) {
                _selectedServiceName = [s.name retain];
            }
        }
    } else {
        if (_selectedServiceName) {
            [_selectedServiceName release];
        }
        _selectedServiceName = nil;
    }
    
    if (_networkPopOverController != nil) {
        _networkPopOverController.selectedServiceName = _selectedServiceName;
        [_networkPopOverController reloadNetwork];
    }
}

- (void)initFirstResponder
{
    // Wu:Make the NSTextView as the first responder
    AppDelegate *appDel = (AppDelegate *)[NSApp delegate];
    [appDel.window makeFirstResponder:_textViewController.textField];
    appDel.window.initialFirstResponder = _textViewController.textField;
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
    if ([message.state isEqualToString:kWDMessageStateFile]) {
        NSArray *originalMessages = [NSArray arrayWithArray:_historyPopOverController.fileHistoryArray];
        for (WDMessage *m in originalMessages) {
            if (([m.fileURL.path isEqualToString:message.fileURL.path])
                &&(![m.state isEqualToString:kWDMessageStateFile])) {
                m.state = kWDMessageStateFile;
            };
        }
    } else {
        [_historyPopOverController.fileHistoryArray addObject:message];
    }

    [_historyPopOverController.fileHistoryArray sortUsingComparator:^NSComparisonResult(WDMessage *obj1, WDMessage * obj2) {
        if ([obj1.time compare:obj2.time] == NSOrderedAscending)
            return NSOrderedAscending;
        else if ([obj1.time compare:obj2.time] == NSOrderedDescending)
            return NSOrderedDescending;
        else
            return NSOrderedSame;
    }];
    [_historyPopOverController.filehistoryTableView reloadData];
}

- (void)sendFile {
    if (_isView == kTextViewController || _fileURL == nil ) {
        return ;
    }
    
    WDMessage *t = [[WDMessage messageWithFile:_fileURL andState:kWDMessageStateReadyToSend] retain];
    if ([self sendToSelectedServiceOfMessage:t]) {
        [self storeMessage:t];
    }
    //[_bubble broadcastMessage:t];
    [t release];  
}

- (void)sendText {
    if (_isView == kTextViewController || [_textViewController.textField.string length] == 0) {
        WDMessage *t = [WDMessage messageWithText:_textViewController.textField.string];
        if ([self sendToSelectedServiceOfMessage:t]) {
            [self storeMessage:t];
        }
        //[_bubble broadcastMessage:t];
    }   
}

#pragma mark - init & dealloc

- (id)init
{
    if (self = [super init]) {
        // Wu: init bubbles
        
        // DW: sound
        _sound = [[WDSound alloc] init];
        
        // DW: we specify user's home directory by NSHomeDirectory()
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"file://localhost%@/Documents/Deliver/", NSHomeDirectory()]];
        NSFileManager *fileManager= [NSFileManager defaultManager]; 
        if(![fileManager fileExistsAtPath:url.path isDirectory:nil])
            if(![fileManager createDirectoryAtPath:url.path withIntermediateDirectories:YES attributes:nil error:NULL])
                NSLog(@"Error: Create folder failed %@", url);
        [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObject:url.path
                                                                                            forKey:kUserDefaultMacSavingPath]];
        
        _bubble = [[WDBubble alloc] init];
        _bubble.delegate = self;
        
        // Wu:Init two popover
        _historyPopOverController = [[HistoryPopOverViewController alloc]
                                     initWithNibName:@"HistoryPopOverViewController" bundle:nil];
        _historyPopOverController.bubbles = _bubble;
        
        _networkPopOverController = [[NetworkFoundPopOverViewController alloc]
                                     initWithNibName:@"NetworkFoundPopOverViewController" bundle:nil];
        _networkPopOverController.bubble = _bubble;
        _networkPopOverController.delegate = self;
        
        //Wu:the initilization is open the send text view;
        _isView = kTextViewController;
        
        //_sound = [[WDSound alloc]init];
        
        [self loadUserPreference];
    }
    return self;
}

- (void)dealloc
{
    // DW: sound
    [_sound release];
    
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
    [_featureController release];
    [_aboutController release];
    
    [_lockButton release];
    [_selectFileItem release];
    [_selectFileOpenPanel release];
    
    [_bubble release];
    // [_sound release];
    [_fileURL release];
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(initFirstResponder) name:@"NSWindowDidBecomeKeyNotification" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(servicesUpdated:) 
                                                 name:kWDBubbleNotificationServiceUpdated
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
    
    _sendButton.stringValue = kButtonTitleSendText;
    
    [self firstUse];
    
    //_menuItemCheck = FALSE;
    
   // [_addFileItem setEnabled:NO];
}

#pragma mark - IBActions

- (IBAction)showPassworFromShortCut:(id)sender
{
    _lockButton.state = !_lockButton.state;
    if (  _lockButton.state) {
        // DW: user turned password on.
        if (_passwordController == nil) {
            _passwordController = [[PasswordMacViewController alloc]init];
            _passwordController.delegate = self;
        }
        
        // Wu: show as a sheet window to force users to set usable password
        [NSApp beginSheet:[_passwordController window] modalForWindow:[NSApplication sharedApplication].keyWindow  modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
    } else {
        NSArray* toolbarVisibleItems = [_toolBar visibleItems];
        NSEnumerator* enumerator = [toolbarVisibleItems objectEnumerator];
        NSToolbarItem* anItem = nil;
        BOOL stillLooking = YES;
        while ( stillLooking && ( anItem = [enumerator nextObject] ) )
        {
            if ( [[anItem itemIdentifier] isEqualToString:@"PasswordIdentifier"] )
            {
                [anItem setImage:[NSImage imageNamed:@"NSLockUnlockedTemplate"]];
                
                stillLooking = NO;
            }
        }
        
        _lockButton.state = NSOffState;
        [_bubble stopService];
        [_bubble publishServiceWithPassword:@""];
        [_bubble browseServices];
    }
}

- (IBAction)showPassword:(id)sender
{
    if (_lockButton.state == NSOnState) {
        // DW: user turned password on.
        if (_passwordController == nil) {
            _passwordController = [[PasswordMacViewController alloc]init];
            _passwordController.delegate = self;
        }
        
        // Wu: show as a sheet window to force users to set usable password
        [NSApp beginSheet:[_passwordController window] modalForWindow:[NSApplication sharedApplication].keyWindow  modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
        
    } else {
        
        NSArray* toolbarVisibleItems = [_toolBar visibleItems];
        NSEnumerator* enumerator = [toolbarVisibleItems objectEnumerator];
        NSToolbarItem* anItem = nil;
        BOOL stillLooking = YES;
        while ( stillLooking && ( anItem = [enumerator nextObject] ) )
        {
            if ( [[anItem itemIdentifier] isEqualToString:@"PasswordIdentifier"] )
            {
                [anItem setImage:[NSImage imageNamed:@"NSLockUnlockedTemplate"]];
                
                stillLooking = NO;
            }
        }
        
        _lockButton.state = NSOffState;
        [_bubble stopService];
        [_bubble publishServiceWithPassword:@""];
        [_bubble browseServices];
    }
}

- (IBAction)showPreferencePanel:(id)sender
{
    if (_preferenceController == nil) {
        _preferenceController = [[PreferenceViewContoller alloc]init];
    }
    
    [_preferenceController showWindow:self];
}

- (IBAction)swapView:(id)sender {
    if (_isView == kTextViewController) {
        [_toolBar insertItemWithItemIdentifier:@"SelectItemIdentifier" atIndex:kTooBarIndexOfSelectButton];
        _isView = kDragFileController;
        [_addFileItem setEnabled:YES];
        [_textViewController.view setHidden:YES withFade:YES];
        [_dragFileController.view setHidden:NO withFade:YES];
        _sendButton.stringValue = kButtonTitleSendFile;
        
    } else {
        AppDelegate *appDel = (AppDelegate *)[NSApp delegate];
        //Reset as first responder
        [appDel.window makeFirstResponder:_textViewController.textField];
        appDel.window.initialFirstResponder = _textViewController.textField;
        
        [_addFileItem setEnabled:NO];
        [_toolBar removeItemAtIndex:kTooBarIndexOfSelectButton];
        _isView = kTextViewController;
        [_textViewController.view setHidden:NO withFade:YES];
        [_dragFileController.view setHidden:YES withFade:YES];
        _sendButton.stringValue = kButtonTitleSendText;
    }
}

- (IBAction)openHistoryPopOver:(id)sender
{
    NSButton *button  = (NSButton *)[_historyItem view];
    [_historyPopOverController showHistoryPopOver:button];
}

- (IBAction)openServiceFoundPopOver:(id)sender
{
    _networkPopOverController.selectedServiceName = _selectedServiceName;
    NSButton *button  = (NSButton *)[_networkItem view];
    [_networkPopOverController showServicesFoundPopOver:button];
}

- (IBAction)send:(id)sender {
    
    if (_isView == kTextViewController) {
        [self sendText];
    } else {
        [self sendFile];
    }
    //[_sound playSoundForKey:kWDSoundFileSent];
}

- (IBAction)selectFile:(id)sender
{
    if (_isView == kTextViewController) {
        return ;
    }
    
    _selectFileOpenPanel = [[NSOpenPanel openPanel] retain];
    
    [_selectFileOpenPanel setTitle:@"Choose File"];
	[_selectFileOpenPanel setPrompt:@"Browse"];
	[_selectFileOpenPanel setNameFieldLabel:@"Choose a file:"];

    void (^selectFileHandler)(NSInteger) = ^( NSInteger result )
	{
		NSURL *selectedFileURL = [_selectFileOpenPanel URL];
		
		if(selectedFileURL)
		{
            _fileURL = [selectedFileURL retain];//the path of your selected photo
            NSImage *image = [[NSImage alloc] initWithContentsOfURL:_fileURL];
            if (image != nil) {
                [_dragFileController.imageView setImage:image];
                [image release];   
            }else {
                NSImage *quicklook = [NSImage imageWithPreviewOfFileAtPath:[_fileURL path] asIcon:YES];
                [_dragFileController.imageView setImage:quicklook];
            }
            
            [_dragFileController.label setHidden:YES];
		}
	};
	
	[_selectFileOpenPanel beginSheetModalForWindow:[NSApplication sharedApplication].keyWindow 
							  completionHandler:selectFileHandler];
}

- (IBAction)showFeature:(id)sender
{
    if (_featureController == nil) {
        _featureController = [[FeatureWindowController alloc]init];
    }
    [_featureController showWindow:self];
}

- (IBAction)showAbout:(id)sender
{
    if (_aboutController == nil) {
        _aboutController = [[AboutWindowController alloc]init];
    }
    [_aboutController showWindow:self];
}


#pragma mark - WDBubbleDelegate

- (void)percentUpdated {
    [_historyPopOverController.filehistoryTableView reloadData];
}

- (void)willReceiveMessage:(WDMessage *)message {
    [self storeMessage:message];
}

- (void)didReceiveMessage:(WDMessage *)message {
    [_sound playSoundForKey:kWDSoundFileReceived];
    message.time = [NSDate date];
    if ([message.state isEqualToString:kWDMessageStateText]) {
            _textViewController.textField.string = [[[NSString alloc] initWithData:message.content encoding:NSUTF8StringEncoding] autorelease];
            [self storeMessage:message];
        
    } else if ([message.state isEqualToString:kWDMessageStateFile]) {
        [self storeMessage:message];
        [_dragFileController.label setHidden:YES];
        
        // DW: store this url for drag and drop
        if (_fileURL) {
            [_fileURL release];
        }
        _fileURL = [message.fileURL retain];
        
        NSImage *image = [[NSImage alloc] initWithContentsOfURL:message.fileURL];
        if (image != nil) {
            [_dragFileController.imageView setImage:image];
            [image release];
        } else {
            NSImage *quicklook = [NSImage imageWithPreviewOfFileAtPath:[message.fileURL path] asIcon:YES];
            [_dragFileController.imageView setImage:quicklook];
        }
    }
    
}

- (void)didSendMessage:(WDMessage *)message {
    [_sound playSoundForKey:kWDSoundFileSent];
    message.state = kWDMessageStateFile;
}

- (void)didTerminateReceiveMessage:(WDMessage *)message {
}

- (void)didTerminateSendMessage:(WDMessage *)message {
    
}

#pragma mark - PasswordMacViewControllerDelegate

- (void)didCancel {
    NSArray* toolbarVisibleItems = [_toolBar visibleItems];
    NSEnumerator* enumerator = [toolbarVisibleItems objectEnumerator];
    NSToolbarItem* anItem = nil;
    BOOL stillLooking = YES;
    while ( stillLooking && ( anItem = [enumerator nextObject] ) )
    {
        if ( [[anItem itemIdentifier] isEqualToString:@"PasswordIdentifier"] )
        {
            [anItem setImage:[NSImage imageNamed:@"NSLockUnlockedTemplate"]];
            
            stillLooking = NO;
        }
    }
    _lockButton.state = NSOffState;
    [_bubble stopService];
    [_bubble publishServiceWithPassword:@""];
    [_bubble browseServices];
}

- (void)didInputPassword:(NSString *)pwd {
    NSArray* toolbarVisibleItems = [_toolBar visibleItems];
    NSEnumerator* enumerator = [toolbarVisibleItems objectEnumerator];
    NSToolbarItem* anItem = nil;
    BOOL stillLooking = YES;
    while ( stillLooking && ( anItem = [enumerator nextObject] ) )
    {
        if ( [[anItem itemIdentifier] isEqualToString:@"PasswordIdentifier"] )
        {
            [anItem setImage:[NSImage imageNamed:@"NSLockLockedTemplate"]];
            
            stillLooking = NO;
        }
    }
    _lockButton.state = NSOnState;
    [_bubble stopService];
    [_bubble publishServiceWithPassword:pwd];
    [_bubble browseServices];
    [_networkPopOverController reloadNetwork];
}

#pragma mark - DragAndDropImageViewDelegate

- (void)dragDidFinished:(NSURL *)url
{
    DLog(@"dragDidFinished");
    if (_fileURL) {
        [_fileURL release];
    }
    _fileURL = [url retain];
    [_dragFileController.label setHidden:YES];
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

#pragma mark - NetworkFoundDelegate

- (void)didSelectServiceName:(NSString *)serviceName
{
    _selectedServiceName = [serviceName retain];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if (menuItem == _addFileItem && _isView == kDragFileController) {
        return YES;
    } else if (menuItem == _addFileItem && _isView == kTextViewController){
        return NO;
    }
    return YES;
}

@end
