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
        [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:@"NSWindowDidBecomeKeyNotification"];
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

- (void)storeMessage:(WDMessage *)message
{
    DLog(@"storeMessage");
    [_fileHistoryArray addObject:message];
   /* [_fileHistoryArray sortUsingComparator:^(WDMessage *obj1, WDMessage * obj2) {
        if ([obj1.time compare:obj2.time] == NSOrderedAscending)
            return NSOrderedDescending;
        else if ([obj1.time compare:obj2.time] == NSOrderedDescending)
            return NSOrderedAscending;
        else
            return NSOrderedSame;
    }];*/
    [_historyTableView reloadData];
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
        
        _fileHistoryArray = [[NSMutableArray alloc]init];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:@"NSWindowDidBecomeKeyNotification"];
    [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:kWDBubbleNotification];
    [_imageMessage release];
    [_passwordController release];
    [_preferenceController release];
    [_imageAndTextCell release];
    [_fileHistoryArray release];
    [_bubble release];
    [_accessoryView release];
    [_tableView release];
    [_historyTableView release];
    [_fileURL release];
    [_imageMessage release];
    [_textMessage release];
    [_checkBox release];
    [super dealloc];
}

- (void)awakeFromNib
{
    bool status = [[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaultsUsePassword];
    [_checkBox setState:status];
    _imageMessage.delegate = self;
    
    // Wu:Add observer to get the notification when the main menu become key window then the sheet window will appear
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(delayNotification)
                                                 name:@"NSWindowDidBecomeKeyNotification" object:nil];
    
    // Wu:Set the customize the cell for the  only one column
    _imageAndTextCell = [[ImageAndTextCell alloc] init];
    _imageAndTextCell.delegate = self;
    NSTableColumn *column = [[_historyTableView tableColumns] objectAtIndex:0];
    [column setDataCell:_imageAndTextCell];
    
    // Wu:Set the tableview can accept being dragged from
    [_historyTableView registerForDraggedTypes:[NSArray arrayWithObjects:NSFilesPromisePboardType,NSFilenamesPboardType,NSTIFFPboardType,nil]];
	// Wu:Tell NSTableView we want to drag and drop accross applications the default is YES
	[_historyTableView setDraggingSourceOperationMask:NSDragOperationCopy forLocal:NO];
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
}

- (IBAction)sendFile:(id)sender {
     WDMessage *t = [[WDMessage messageWithFile:_fileURL] retain];
    [self storeMessage:t];
    [_bubble broadcastMessage:t];
    [t release];
}

- (IBAction)showPreferencePanel:(id)sender
{
    if (_preferenceController == nil) {
        _preferenceController = [[PreferenceViewContoller alloc]init];
    }
    
    [_preferenceController showWindow:self];
}

- (IBAction)deleteSelectedRows:(id)sender
{
    if ([_historyTableView selectedRow] < 0 || [_historyTableView selectedRow] >= [_fileHistoryArray count]) {
        return ;
    } else {
        [_fileHistoryArray removeObjectAtIndex:[_historyTableView selectedRow]];
        [_historyTableView noteNumberOfRowsChanged];
        [_historyTableView reloadData];
    }
}

- (IBAction)removeAllHistory:(id)sender
{
    if ([_fileHistoryArray count] == 0) {
        return ;
    } else {
        [_fileHistoryArray removeAllObjects];
        [_historyTableView noteNumberOfRowsChanged];
        [_historyTableView reloadData];
    }
}

#pragma mark - WDBubbleDelegate

- (void)didReceiveMessage:(WDMessage *)message ofText:(NSString *)text {
    DLog(@"VC didReceiveText %@", text);
    _textMessage.stringValue = text;
    [self storeMessage:message];
}

- (void)didReceiveMessage:(WDMessage *)message ofFile:(NSURL *)url {
    DLog(@"MVC didReceiveFile %@", url);
    [self storeMessage:message];
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
    if (aTableView == _tableView ) {
        return _bubble.servicesFound.count;
    } else if (aTableView == _historyTableView) {
        DLog(@"numberOfRowsInTableView");
        return [_fileHistoryArray count];
    }
    return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if (aTableView == _tableView) {
        NSNetService *t = [_bubble.servicesFound objectAtIndex:rowIndex];
        if ([t.name isEqualToString:_bubble.service.name]) {
            return [t.name stringByAppendingString:@" (local)"];
        } else {
            return t.name;
        }
    } else if (aTableView == _historyTableView) {
        return [_fileHistoryArray objectAtIndex:rowIndex];
    }
    return nil;
}

- (BOOL)   tableView:(NSTableView *)pTableView 
writeRowsWithIndexes:(NSIndexSet *)pIndexSetOfRows 
		toPasteboard:(NSPasteboard*)pboard
{
	// Wu:This is to allow us to drag files to save
	// We don't do this if more than one row is selected
    DLog(@"writeRowsWithIndexes");
	if ([pIndexSetOfRows count] > 1) {
		return YES;
	} 
	NSInteger zIndex	= [pIndexSetOfRows firstIndex];
	WDMessage *message	= [_fileHistoryArray objectAtIndex:zIndex];
    
    [pboard declareTypes:[NSArray arrayWithObjects:NSFilesPromisePboardType, nil] owner:self];
    NSArray *propertyArray = [NSArray arrayWithObject:message.fileURL.pathExtension];
    [pboard setPropertyList:propertyArray
                    forType:NSFilesPromisePboardType];
    return YES;
}

- (NSArray *)tableView:(NSTableView *)aTableView
namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination
forDraggedRowsWithIndexes:(NSIndexSet *)indexSet {
    DLog(@"namesOfPromisedFilesDroppedAtDestination");
    NSInteger zIndex = [indexSet firstIndex];
    WDMessage *message = [_fileHistoryArray objectAtIndex:zIndex];
    
    NSURL *newURL = [NSURL URLWithString:[NSString stringWithFormat:@"file://%@/%@", 
                                          dropDestination.path, 
                                          [message.fileURL.lastPathComponent stringByReplacingOccurrencesOfString:@" " 
                                                                                                      withString:@"%20"]]];
    newURL = [newURL URLWithoutNameConflict];
    NSData *data = [NSData dataWithContentsOfURL:message.fileURL];
    [[NSFileManager defaultManager] createFileAtPath:newURL.path contents:data attributes:nil];
    return [NSArray arrayWithObjects:newURL.lastPathComponent, nil];
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
}

- (NSURL *)dataDraggedToSave
{
    if (_fileURL && _imageMessage.image != nil) {
        return _fileURL;
    }
    return nil;
}

#pragma mark - ImageAndTextCellDelegate

- (NSImage *)previewIconForCell:(NSObject *)data
{
    DLog(@"previewIconForCell");
    WDMessage *message = (WDMessage *)data;
    if (message.type == WDMessageTypeText){
        return nil;
    } else if (message.type == WDMessageTypeFile){
        NSImage *icon = [[[NSImage alloc]initWithContentsOfURL:message.fileURL]autorelease];
        return icon;
    }
    return nil;
}

- (NSString *)primaryTextForCell:(NSObject *)data
{
    DLog(@"primaryTextForCell");
    WDMessage *message = (WDMessage *)data;
    if (message.type == WDMessageTypeText){
        return [[[NSString alloc] initWithData:message.content encoding:NSUTF8StringEncoding] autorelease];
    } else if (message.type == WDMessageTypeFile){
        return [message.fileURL lastPathComponent];
    }
    return nil;
}

- (NSString *)auxiliaryTextForCell:(NSObject *)data
{
    WDMessage *message = (WDMessage *)data;
    NSDateFormatter *df = [[[NSDateFormatter alloc] init] autorelease];
    df.dateFormat = @"hh:mm:ss";
    return  [message.sender stringByAppendingFormat:@" %@", [df stringFromDate:message.time]];
}

- (NSURL *)URLForCell:(NSObject *)data
{
    WDMessage *message = (WDMessage *)data;
    return  message.fileURL;
}

@end
