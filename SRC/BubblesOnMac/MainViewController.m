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
    
    bool status = [[NSUserDefaults standardUserDefaults] boolForKey:kMACUserDefaultsUsePassword];
    
    if (status) {
        _passwordController = [[PasswordMacViewController alloc]init];
        _passwordController.delegate = self;
        
        [NSApp beginSheet:[_passwordController window] modalForWindow:[NSApplication sharedApplication].mainWindow modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
        
    } else {
        [_bubble publishServiceWithPassword:@""];
        [_bubble browseServices];
    }
}

- (void)delayNotification
{
    [self performSelector:@selector(loadUserPreference) withObject:nil afterDelay:1.0f];
}

- (id)init
{
    if (self = [super init]) {
        // Wu: init bubbles
        
        [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObject:@"file://localhost/Users/wuwuziqi/Downloads/" forKey:KUserDefaultSavingPath]];
        
        _bubble = [[WDBubble alloc] init];
        _bubble.delegate = self;
        
        // Wu: Add observer to update service 
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(servicesUpdated:) 
                                                     name:kWDBubbleNotification
                                                   object:nil];
        
        [_imageMessage registerForDraggedTypes:[NSImage imagePasteboardTypes]];
        // Wu: register for all the image types we can display
        
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
    bool status = [[NSUserDefaults standardUserDefaults] boolForKey:kMACUserDefaultsUsePassword];
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
    [[NSUserDefaults standardUserDefaults] setBool:button.state forKey:kMACUserDefaultsUsePassword];
    
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
            NSImage *quicklook = [NSImage imageWithPreviewOfFileAtPath:[_fileURL path] ofSize:CGSizeMake(50, 50) asIcon:YES];
            [_imageMessage setImage:quicklook];
        }
    }
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

- (IBAction)directlySave:(id)sender
{
    NSURL *url = [[NSUserDefaults standardUserDefaults] URLForKey:KUserDefaultSavingPath];
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

#pragma mark - WDBubbleDelegate

- (void)didReceiveText:(NSString *)text {
    DLog(@"VC didReceiveText %@", text);
    _textMessage.stringValue = text;
}

- (void)didReceiveImage:(NSImage *)image {
    DLog(@"MVC didReceiveImage %@", image);
    _imageMessage.image = image;
}

- (void)didReceiveFile:(NSURL *)url {
    NSLog(@"MVC didReceiveFile %@", url);
    NSImage *image = [[NSImage alloc] initWithContentsOfURL:url];
    if (image != nil) {
        [_imageMessage setImage:image];
        [image release];   
    }else {
        NSImage *quicklook = [NSImage imageWithPreviewOfFileAtPath:[url path] ofSize:CGSizeMake(50, 50) asIcon:YES];
        [_imageMessage setImage:quicklook];
    }
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
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kMACUserDefaultsUsePassword];
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
    DLog(@"haha url got it");
    if (_fileURL) {
        [_fileURL release];
    }
    _fileURL = [url retain];
}

- (NSURL *)dataDraggedToSave
{
    if (_fileURL && _imageMessage.image != nil) {
        return _fileURL;
    }
    return nil;
}
@end
