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

#pragma mark - Private Methods

- (void)servicesUpdated:(NSNotification *)notification {
    [_tableView reloadData];
}

- (void)loadUserPreference
{
    if (_passwordController != nil) {
        return ;
    }
    
    bool status = [[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaultsUsePassword];
    
    if (status) {
        _passwordController = [[PasswordMacViewController alloc]init];
        _passwordController.delegate = self;
        
        [NSApp beginSheet:[_passwordController window] modalForWindow:[NSApplication sharedApplication].mainWindow modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
        
    } else {
        [_bubble publishServiceWithPassword:@""];
        [_bubble browseServices];
    }
}

- (void)delayNotification {
    [self performSelector:@selector(loadUserPreference) withObject:nil afterDelay:1.0f];
}

// DW: we do not need this method now
- (void)directlySave {
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
}

#pragma mark - init & dealloc

- (id)init
{
    if (self = [super init]) {
        // Wu: init bubbles
        
        [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObject:@"file://localhost/~/Downloads/" forKey:kUserDefaultMacSavingPath]];
        
        _bubble = [[WDBubble alloc] init];
        _bubble.delegate = self;
        
        // Wu: Add observer to update service 
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(servicesUpdated:) 
                                                     name:kWDBubbleNotification
                                                   object:nil];        
    }
    return self;
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"NSWindowDidBecomeKeyNotification"];
    [self removeObserver:self forKeyPath:kWDBubbleNotification];
    [_passwordController release];
    [_preferenceController release];
    [_bubble release];
    [_accessoryView release];
    [_fileURL release];
    [super dealloc];
}

- (void)awakeFromNib
{
    bool status = [[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaultsUsePassword];
    DLog(@"status is %d",status);
    [_checkBox setState:status];
    
    _imageMessage.delegate = self;
    
    //add observer to get the notification when the main menu become key window then the sheet window will appear
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(delayNotification)
                                                 name:@"NSWindowDidBecomeKeyNotification" object:nil];
}

#pragma mark - IBActions

- (IBAction)sendText:(id)sender {
    [_bubble broadcastMessage:[WDMessage messageWithText:_textMessage.stringValue]];
}

- (IBAction)togglePassword:(id)sender {
    NSButton *button = (NSButton *)sender;
    [[NSUserDefaults standardUserDefaults] setBool:button.state forKey:kUserDefaultsUsePassword];
    
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
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];

	[openPanel setTitle:@"Choose File"];
	[openPanel setPrompt:@"Browse"];
	[openPanel setNameFieldLabel:@"Choose a file:"];
    
    if ([openPanel runModal] == NSFileHandlingPanelOKButton) {
        _fileURL = [[openPanel URL] retain];//the path of your selected photo
        NSImage *image = [[NSImage alloc] initWithContentsOfURL:_fileURL];
        
        if (image != nil) {
            [_imageMessage setImage:image];
            [image release];   
        }else {
            NSImage *quicklook = [NSImage imageWithPreviewOfFileAtPath:[_fileURL path] asIcon:YES];
            [_imageMessage setImage:quicklook];
        }
    }
    AppDelegate *del = (AppDelegate *)[NSApp delegate];
    del.array = [NSArray arrayWithObject:_fileURL];
}

- (IBAction)sendFile:(id)sender {
    [_bubble broadcastMessage:[WDMessage messageWithFile:_fileURL]];
}

- (IBAction)showPreferencePanel:(id)sender
{
    if (_preferenceController == nil) {
        _preferenceController = [[PreferenceViewContoller alloc]init];
    }
    
    [_preferenceController showWindow:self];
}

#pragma mark - WDBubbleDelegate

- (void)didReceiveMessage:(WDMessage *)message ofText:(NSString *)text {
    DLog(@"VC didReceiveText %@", text);
    _textMessage.stringValue = text;
}

- (void)didReceiveMessage:(WDMessage *)message ofFile:(NSURL *)url {
    DLog(@"MVC didReceiveFile %@", url);
    
    // DW: store this url for drag and drop
    if (_fileURL) {
        [_fileURL release];
    }
    _fileURL = [url retain];
    
    NSImage *image = [[NSImage alloc] initWithContentsOfURL:url];
    if (image != nil) {
        [_imageMessage setImage:image];
        [image release];
    } else {
        NSImage *quicklook = [NSImage imageWithPreviewOfFileAtPath:[url path] asIcon:YES];
        [_imageMessage setImage:quicklook];
    }
    AppDelegate *del = (AppDelegate *)[NSApp delegate];
    del.array = [NSArray arrayWithObject:_fileURL];
}

#pragma mark - NSTableViewDelegate

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    //comment by wuziqi 
    //This is used for select other devices to connect
    //To be finished
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return _bubble.servicesFound.count;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    NSNetService *t = [_bubble.servicesFound objectAtIndex:rowIndex];
    
    if ([t.name isEqualToString:_bubble.service.name]) {
        return [t.name stringByAppendingString:@" (local)"];
    } else {
        return t.name;
    }
}

#pragma mark - PasswordMacViewControllerDelegate

- (void)didCancel {
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kUserDefaultsUsePassword];
    _checkBox.state = NSOffState;
}

- (void)didInputPassword:(NSString *)pwd {
    [_bubble stopService];
    [_bubble publishServiceWithPassword:pwd];
    [_bubble browseServices];
}

#pragma mark - DragAndDropImageViewDelegate

- (void)dragDidFinished:(NSURL *)url
{
    if (_fileURL) {
        [_fileURL release];
    }
    _fileURL = [url retain];
    AppDelegate *del = (AppDelegate *)[NSApp delegate];
    del.array = [NSArray arrayWithObject:_fileURL];
    
}

- (NSURL *)dataDraggedToSave
{
    if (_fileURL && _imageMessage.image != nil) {
        return _fileURL;
    }
    return nil;
}


@end
