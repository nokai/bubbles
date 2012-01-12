//
//  MainViewController.m
//  Bubbles
//
//  Created by 吴 wuziqi on 12-1-11.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import "MainViewController.h"

@implementation MainViewController

@synthesize checkBox = _checkBox;
@synthesize textMessage = _textMessage;
@synthesize imageMessage = _imageMessage;
@synthesize bubble = _bubble;
@synthesize tableView = _tableView;
@synthesize passwordController = _passwordController;

-(id)init
{
    self = [super init];
    if (self) {
        //init bubbles
        _bubble = [[WDBubble alloc] init];
        _bubble.delegate = self;
        [_bubble initSocket];
        
        [self LoadUserPreference];
               
        //Add observer to update service 
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(servicesUpdated:) 
                                                     name:kWDBubbleNotification
                                                   object:nil];
    }
    return self;
}

-(void)dealloc
{
    [self removeObserver:self forKeyPath:kWDBubbleNotification];
    [_passwordController release];
    [_checkBox release];
    [_tableView release];
    [_textMessage release];
    [_imageMessage release];
    [_bubble release];
}

#pragma mark - 
#pragma mark IBAction

- (IBAction)sendText:(id)sender {
    [_bubble broadcastMessage:[WDMessage messageWithText:_textMessage.stringValue]];
    [_textMessage resignFirstResponder];
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
    
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    
    //jpg and png is just for test ....
	[openPanel setAllowedFileTypes:[NSArray arrayWithObjects:@"png",@"jpg",nil]];
	[openPanel setTitle:@"Choose a picture"];
	[openPanel setPrompt:@"Browse"];
	[openPanel setNameFieldLabel:@"Choose a picture:"];
     
    if ([openPanel runModal] == NSFileHandlingPanelOKButton)
    {
        NSURL *url = [openPanel URL];//the path of your selected photo
        NSImage *image = [[NSImage alloc] initWithContentsOfURL:url];
        [_imageMessage setImage:image];
        [image release];
        
        [_bubble broadcastMessage:[WDMessage messageWithImage:_imageMessage.image]];
    }
}

- (IBAction)clickBox:(id)sender {
    NSButton *button = (NSButton *)sender;
    [[NSUserDefaults standardUserDefaults] setBool:button.state forKey:kMACUserDefaultsUsePassword];
    
    if (button.state == NSOnState) {
        [_bubble  stopService];
        
        _passwordController = [[PasswordMacViewController alloc]init];
        _passwordController.delegate = self;
        
        [_passwordController showWindow:self];
    }
    else
    {
        [self.bubble stopService];
        [self.bubble publishServiceWithPassword:@""];
        [self.bubble browseServices];
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

#pragma mark - NSTableViewDelegate

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
   //comment by wuziqi 
   //This is used for select other devices to connect
   //To be finished
}

#pragma mark - NSTableViewDataSource

-(NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return _bubble.servicesFound.count;
}

- (id)tableView:(NSTableView *)aTableView 
objectValueForTableColumn:(NSTableColumn *)aTableColumn 
            row:(NSInteger)rowIndex
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


#pragma mark - 
#pragma mark Private

- (void)servicesUpdated:(NSNotification *)notification {
    [_tableView reloadData];
}

- (void)LoadUserPreference
{
    bool status = [[NSUserDefaults standardUserDefaults] boolForKey:kMACUserDefaultsUsePassword];
    DLog(@"status is %d",status);
    [_checkBox setState:status];
    
    if (status) {
        _passwordController = [[PasswordMacViewController alloc]init];
        _passwordController.delegate = self;
        [_passwordController showWindow:self];
    }
    
    else
    {
        [_bubble publishServiceWithPassword:@""];
        [_bubble browseServices];
    }
}

@end
