//
//  MainViewController.m
//  Bubbles
//
//  Created by 吴 wuziqi on 12-1-11.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import "MainViewController.h"

@implementation MainViewController

#pragma mark - Private Methods

- (void)servicesUpdated:(NSNotification *)notification {
    [_tableView reloadData];
}

- (void)loadUserPreference
{
    bool status = [[NSUserDefaults standardUserDefaults] boolForKey:kMACUserDefaultsUsePassword];
    
    if (status) {
        _passwordController = [[PasswordMacViewController alloc]init];
        _passwordController.delegate = self;
        [_passwordController showWindow:self];
    } else {
        [_bubble publishServiceWithPassword:@""];
        [_bubble browseServices];
    }
}

- (id)init
{
    if (self = [super init]) {
        //init bubbles
        
        _bubble = [[WDBubble alloc] init];
        _bubble.delegate = self;
        
        [self loadUserPreference];
        
        //Add observer to update service 
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(servicesUpdated:) 
                                                     name:kWDBubbleNotification
                                                   object:nil];
        
        [_imageMessage registerForDraggedTypes:[NSImage imagePasteboardTypes]];
        //register for all the image types we can display
    }
    return self;
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:kWDBubbleNotification];
    [_passwordController release];
    [_bubble release];
}

- (void)awakeFromNib
{
    bool status = [[NSUserDefaults standardUserDefaults] boolForKey:kMACUserDefaultsUsePassword];
    DLog(@"status is %d",status);
    [_checkBox setState:status];
}

#pragma mark - IBActions

- (IBAction)sendText:(id)sender {
    [_bubble broadcastMessage:[WDMessage messageWithText:_textMessage.stringValue]];
}

- (IBAction)saveImage:(id)sender {
    
    if (_imageMessage.image) {
        
        NSSavePanel *savePanel = [NSSavePanel savePanel];
        
        //for test ,only two types
        [savePanel setAllowedFileTypes:[NSArray arrayWithObjects:@"png",@"jpg",nil]];
        [savePanel setTitle:@"Save"];
        [savePanel setPrompt:@"Save"];
        [savePanel setNameFieldLabel:@"Save picture to:"];
        
        if ([savePanel runModal] == NSFileHandlingPanelOKButton) {
            NSURL *url = [savePanel URL];
            
            NSData *imageData = [_imageMessage.image TIFFRepresentation];
            NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
            NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
            imageData = [imageRep representationUsingType:NSJPEGFileType properties:imageProps];
            [imageData writeToURL:url atomically:NO];  
        }
    }
}

- (IBAction)sendImage:(id)sender {
    //[_bubble broadcastMessage:[WDMessage messageWithImage:_imageMessage.image]];
    // 20120120 DW: files not images
    [_bubble broadcastMessage:[WDMessage messageWithFile:_fileURL]];
}

- (IBAction)clickBox:(id)sender {
    NSButton *button = (NSButton *)sender;
    [[NSUserDefaults standardUserDefaults] setBool:button.state forKey:kMACUserDefaultsUsePassword];
    
    if (button.state == NSOnState) {
        [_bubble  stopService];
        
        if (_passwordController == nil) {
            _passwordController = [[PasswordMacViewController alloc]init];
            _passwordController.delegate = self;
        }
        
        [_passwordController showWindow:self];
    } else {
        [_bubble stopService];
        
        if (_passwordController != nil) {
            [_passwordController close];
        }
        
        [_bubble publishServiceWithPassword:@""];
        [_bubble browseServices];
    }
}

- (IBAction)browseImage:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    
    //jpg and png is just for test ....
	//[openPanel setAllowedFileTypes:[NSArray arrayWithObjects:@"png",@"jpg",nil]];
	[openPanel setTitle:@"Choose File"];
	[openPanel setPrompt:@"Browse"];
	[openPanel setNameFieldLabel:@"Choose a file:"];
    
    if ([openPanel runModal] == NSFileHandlingPanelOKButton)
    {
        _fileURL = [[openPanel URL] retain];//the path of your selected photo
        //NSImage *image = [[NSImage alloc] initWithContentsOfURL:url];
        //[_imageMessage setImage:image];
        //[image release];
        DLog(@"Selected %@", _fileURL);
    }
    
}

#pragma mark - WDBubbleDelegate

- (void)didReceiveText:(NSString *)text {
    DLog(@"VC didReceiveText %@", text);
    _textMessage.stringValue = text;
}

- (void)didReceiveImage:(NSImage *)image {
    DLog(@"VC didReceiveImage %@", image);
    _imageMessage.image = image;
}

- (void)didReceiveFile:(NSURL *)url {
    
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

#pragma mark - 
#pragma mark PasswordMacViewControllerDelegate

- (void)didInputPassword:(NSString *)pwd
{
    [_passwordController close];
    [_bubble publishServiceWithPassword:pwd];
    [_bubble browseServices];
}

#pragma mark - DragAndDropImageViewDelegate

- (void)dropComplete:(NSString *)filePath
{
    DLog(@"path is %@",filePath);
    [_bubble broadcastMessage:[WDMessage messageWithImage:_imageMessage.image]];
}

@end
