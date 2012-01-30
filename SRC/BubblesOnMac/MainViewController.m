//
//  MainViewController.m
//  Bubbles
//
//  Created by 吴 wuziqi on 12-1-11.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import "MainViewController.h"
#import <QuickLook/QuickLook.h>

@interface NSImage (QuickLook)
+ (NSImage *)imageWithPreviewOfFileAtPath:(NSString *)path ofSize:(NSSize)size asIcon:(BOOL)icon;
@end

@implementation NSImage (QuickLook)

+ (NSImage *)imageWithPreviewOfFileAtPath:(NSString *)path ofSize:(NSSize)size asIcon:(BOOL)icon
{
    NSURL *fileURL = [NSURL fileURLWithPath:path];
    if (!path || !fileURL) {
        return nil;
    }
    
    NSDictionary *dict = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:icon] 
                                                     forKey:(NSString *)kQLThumbnailOptionIconModeKey];
    CGImageRef ref = QLThumbnailImageCreate(kCFAllocatorDefault, 
                                            (CFURLRef)fileURL, 
                                            CGSizeMake(size.width, size.height),
                                            (CFDictionaryRef)dict);
    
    if (ref != NULL) {
        // Take advantage of NSBitmapImageRep's -initWithCGImage: initializer, new in Leopard,
        // which is a lot more efficient than copying pixel data into a brand new NSImage.
        // Thanks to Troy Stephens @ Apple for pointing this new method out to me.
        NSBitmapImageRep *bitmapImageRep = [[NSBitmapImageRep alloc] initWithCGImage:ref];
        NSImage *newImage = nil;
        if (bitmapImageRep) {
            newImage = [[NSImage alloc] initWithSize:[bitmapImageRep size]];
            [newImage addRepresentation:bitmapImageRep];
            [bitmapImageRep release];
            
            if (newImage) {
                return [newImage autorelease];
            }
        }
        CFRelease(ref);
    } else {
        // If we couldn't get a Quick Look preview, fall back on the file's Finder icon.
        NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:path];
        if (icon) {
            [icon setSize:size];
        }
        return icon;
    }
    return nil;
}
@end

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
        //init bubbles
        
        [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObject:@"file://localhost/Users/wuwuziqi/Downloads/" forKey:KUserDefaultSavingPath]];
        
        _bubble = [[WDBubble alloc] init];
        _bubble.delegate = self;
        
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
    [self removeObserver:self forKeyPath:@"NSWindowDidBecomeKeyNotification"];
    [self removeObserver:self forKeyPath:kWDBubbleNotification];
    [_passwordController release];
    [_preferenceController release];
    [_bubble release];
    [_accessoryView release];
    [_directlySave release];
    [_fileURL release];
    [super dealloc];
}

- (void)awakeFromNib
{
    bool status = [[NSUserDefaults standardUserDefaults] boolForKey:kMACUserDefaultsUsePassword];
    DLog(@"status is %d",status);
    [_checkBox setState:status];
    
    //add observer to get the notification when the main menu become key window then the sheet window will appear
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(delayNotification)
                                                 name:@"NSWindowDidBecomeKeyNotification" object:nil];
}

#pragma mark - IBActions

- (IBAction)sendText:(id)sender {
    [_bubble broadcastMessage:[WDMessage messageWithText:_textMessage.stringValue]];
}

- (IBAction)saveImage:(id)sender {
    
    if (_imageMessage.image) {
        
        NSSavePanel *savePanel = [NSSavePanel savePanel];
        
        [savePanel setTitle:@"Save"];
        [savePanel setPrompt:@"Save"];
        [savePanel setNameFieldLabel:@"Save as"];
        [savePanel setAccessoryView:_accessoryView];
        
        if ([savePanel runModal] == NSFileHandlingPanelOKButton) {
            NSURL *url = [savePanel URL];
            
            NSData *imageData = [_imageMessage.image TIFFRepresentation];
            NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
            NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
            imageData = [imageRep representationUsingType:NSTIFFFileType properties:imageProps];
            [imageData writeToURL:url atomically:NO];  
        }
    }
}

- (IBAction)sendFile:(id)sender {
<<<<<<< HEAD
=======
    //[_bubble broadcastMessage:[WDMessage messageWithImage:_imageMessage.image]];
    // 20120120 DW: files not images
>>>>>>> ba086d95262f21667d69470da78897d822c77ec3
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
        
        //show as a sheet window to force users to set usable password
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
    
<<<<<<< HEAD
    if ([openPanel runModal] == NSFileHandlingPanelOKButton) {
        if (_fileURL) {
            [_fileURL release];
        }
        _fileURL = [[openPanel URL] retain];
       NSString *path = [[_fileURL absoluteURL] path];
        NSImage *image = [[NSImage alloc] initWithContentsOfURL:_fileURL];
        if (image != nil) {
            [_imageMessage setImage:image];
            [image release];
        }else
        {
            NSSize size ;
            size.width = 90;
            size.height = 90;
            _imageMessage.image = [NSImage imageWithPreviewOfFileAtPath:path ofSize:size asIcon:YES];
        }
=======
    //jpg and png is just for test ....
	//[openPanel setAllowedFileTypes:[NSArray arrayWithObjects:@"png",@"jpg",nil]];
	[openPanel setTitle:@"Choose File"];
	[openPanel setPrompt:@"Browse"];
	[openPanel setNameFieldLabel:@"Choose a file:"];
    
    if ([openPanel runModal] == NSFileHandlingPanelOKButton) {
        _fileURL = [[openPanel URL] retain];//the path of your selected photo
        //NSImage *image = [[NSImage alloc] initWithContentsOfURL:url];
        //[_imageMessage setImage:image];
        //[image release];
        DLog(@"Selected %@", _fileURL);
>>>>>>> ba086d95262f21667d69470da78897d822c77ec3
    }
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
    if (_imageMessage.image != nil) {
        NSFileManager *manager = [NSFileManager defaultManager];
        NSData *data = [_imageMessage.image TIFFRepresentation];
        NSString *fullPath = [[url path] stringByAppendingPathComponent:@"haha.png"];
        [manager createFileAtPath:fullPath contents:data attributes:nil];
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
    [_imageMessage.image initWithContentsOfURL:url];
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

- (void)didInputPassword:(NSString *)pwd
{
    [_bubble publishServiceWithPassword:pwd];
    [_bubble browseServices];
}

@end
