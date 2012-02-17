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
    DLog(@"storeMessage");
    [_historyPopOverController.fileHistoryArray addObject:message];
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

- (void)sendFile
{
    if (_isView == kTextViewController || _fileURL == nil) {
        return ;
    }
#ifdef TEMP_USE_OLD_WDBUBBLE
    WDMessage *t = [[WDMessage messageWithFile:_fileURL] retain];
#else
    WDMessage *t = [[WDMessage messageWithFile:_fileURL andCommand:kWDMessageControlBegin] retain];
#endif
    [self storeMessage:[WDMessage messageInfoFromMessage:t]];
    [_bubble broadcastMessage:t];
    [t release];  
}

- (void)sendText
{
    if (_isView == kTextViewController || [_textViewController.textField.string length] == 0) {
        WDMessage *t = [WDMessage messageWithText:_textViewController.textField.string];
        [self storeMessage:t];
        [_bubble broadcastMessage:t];
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
    
    [_lockButton release];
    [_selectFileItem release];
    
    [_bubble release];
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
}

#pragma mark - IBActions

- (IBAction)togglePassword:(id)sender {
    //NSButton *button = (NSButton *)sender;
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
        [_textViewController.view setHidden:YES withFade:YES];
        [_dragFileController.view setHidden:NO withFade:YES];
        _sendButton.stringValue = kButtonTitleSendFile;
    } else {
        AppDelegate *appDel = (AppDelegate *)[NSApp delegate];
        [appDel.window makeFirstResponder:_textViewController.textField];
        appDel.window.initialFirstResponder = _textViewController.textField;
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
    NSButton *button  = (NSButton *)[_networkItem view];
    [_networkPopOverController showServicesFoundPopOver:button];
}

- (IBAction)send:(id)sender {
    
    if (_isView == kTextViewController) {
        [self sendText];
    } else {
        [self sendFile];
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
        
        [_dragFileController.label setHidden:YES];
    }
}

#pragma mark - WDBubbleDelegate

- (void)didReceiveMessage:(WDMessage *)message ofText:(NSString *)text {
    if (_isView == kTextViewController) {
        _textViewController.textField.string = text;
        [self storeMessage:message];
    } 
}

- (void)didReceiveMessage:(WDMessage *)message ofFile:(NSURL *)url {
    if (_isView != kDragFileController) {
        return ;
    }
    [self storeMessage:message];
    
    // DW: store this url for drag and drop
    if (_fileURL) {
        [_fileURL release];
    }
    _fileURL = [url retain];
    
    NSImage *image = [[NSImage alloc] initWithContentsOfURL:message.fileURL];
    if (image != nil) {
        [_dragFileController.imageView setImage:image];
        [image release];
    } else {
        NSImage *quicklook = [NSImage imageWithPreviewOfFileAtPath:[message.fileURL path] asIcon:YES];
        [_dragFileController.imageView setImage:quicklook];
    }
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

// DW: we do not need these codes

/*
 #pragma mark - NSToolBarDelegate
 
 - (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
 {
 DLog(@"validateToolbarItem");
 if ([[theItem itemIdentifier] isEqual: @"SelectItemIdentifier"]) {
 return YES;
 } else if ([[theItem itemIdentifier] isEqual:@"PasswordIdentifier"]) {
 return YES;
 } else if ([[theItem itemIdentifier] isEqual:@"HistoryIdentifier"]) {
 return YES;
 } else if ([[theItem itemIdentifier] isEqual:@"NetworkIdentifier"]) {
 return YES;
 }
 return NO;
 }
 
 - (void) toolbarWillAddItem:(NSNotification *)notification {
 NSToolbarItem *addedItem = [[notification userInfo] objectForKey: @"item"];
 
 if ([[addedItem itemIdentifier] isEqual: @"SelectItemIdentifier"]) {
 DLog(@"kjhfkjsdhkjsdhfkjsdhf!!!!");
 }
 }
 
 - (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar {
 return [NSArray arrayWithObjects:
 @"PasswordIdentifier", NSToolbarFlexibleSpaceItemIdentifier,
 @"HistoryIdentifier", @"NetworkIdentifier", nil];
 }
 
 - (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar {
 return [NSArray arrayWithObjects:
 @"PasswordIdentifier",
 NSToolbarFlexibleSpaceItemIdentifier,@"HistoryIdentifier", @"NetworkIdentifier", @"SelectItemIdentifier",nil];
 }
 */

/*
 - (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdent willBeInsertedIntoToolbar:(BOOL)willBeInserted {
 // Required delegate method:  Given an item identifier, this method returns an item 
 // The toolbar will use this method to obtain toolbar items that can be displayed in the customization sheet, or in the toolbar itself 
 
 DLog(@"itemForItemIdentifier");
 NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
 if ([[toolbarItem itemIdentifier] isEqual:@"SelectItemIdentifier"]) {
 [toolbarItem setImage:[NSImage imageNamed:@"NSAddTemplate"]];
 [toolbarItem setLabel:@"Select"];
 [toolbarItem setPaletteLabel:@"Select"];
 [toolbarItem setTarget:self];
 [toolbarItem setAction:@selector(selectFile)];
 }
 
 return toolbarItem;
 }
 */

@end
