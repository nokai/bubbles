//
//  HistoryPopOverViewController.m
//  Bubbles
//
//  Created by 吴 wuziqi on 12-2-9.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import "HistoryPopOverViewController.h"


@implementation HistoryPopOverViewController
@synthesize historyPopOver = _historyPopOver;
@synthesize fileHistoryArray = _fileHistoryArray;
@synthesize filehistoryTableView = _fileHistoryTableView;

#pragma mark - Private Methods

- (void)showItPreview
{
    if (0 <= [_fileHistoryTableView selectedRow] && [_fileHistoryTableView selectedRow] < [_fileHistoryArray count]) {
        WDMessage *message = (WDMessage *)[_fileHistoryArray objectAtIndex:[_fileHistoryTableView selectedRow]];
        AppDelegate *del = (AppDelegate *)[NSApp delegate];
        if (![del.array containsObject:message.fileURL]) {
            del.array = [NSArray arrayWithObject:message.fileURL];
        }
        [del showPreviewInHistory];
    }
}

- (void)showItFinder:(NSURL *)aFileURL
{
    // Wu:Use NSWorkspace to open Finder with specific NSURL and show the selected status 
    [[NSWorkspace sharedWorkspace]selectFile:[aFileURL path] inFileViewerRootedAtPath:nil];
}

- (void)deleteSelectedRow
{
    if (0 <= [_fileHistoryTableView selectedRow] && [_fileHistoryTableView selectedRow] < [_fileHistoryArray count]) {
        [_fileHistoryArray removeObjectAtIndex:[_fileHistoryTableView selectedRow]];
    }
    if ([_fileHistoryArray count] == 0) {
        [_removeButton setHidden:YES];
        [_historyPopOver close];
    }
    [_fileHistoryTableView reloadData];
}

- (void)previewSelectedRow
{
    if (0 <= [_fileHistoryTableView selectedRow] && [_fileHistoryTableView selectedRow] < [_fileHistoryArray count]) {
        WDMessage *message = (WDMessage *)[_fileHistoryArray objectAtIndex:[_fileHistoryTableView selectedRow]];
        [self showItFinder:message.fileURL];
    }
}

- (NSString *)escapedStringFromURL:(NSURL *)aURL
{
    // Wu:In case the url contains unicode string
    NSString *lastComponents = [NSString stringWithString:[aURL lastPathComponent]];
    NSString *unescapedString = [lastComponents stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *escapedString = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)unescapedString, NULL, NULL, kCFStringEncodingUTF8);
    return [escapedString autorelease];
}

#pragma mark - LifeCycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _fileHistoryArray = [[NSMutableArray alloc]init];
    }
    
    return self;
}

- (void)dealloc
{
    [_imageAndTextCell release];
    [_fileHistoryTableView release];
    [_fileHistoryArray release];
    [_historyPopOver release];
    [super dealloc];
}

- (void)awakeFromNib
{
    // Wu:Set the customize the cell for the  only one column
    _imageAndTextCell = [[ImageAndTextCell alloc] init];
    _imageAndTextCell.delegate = self;
    NSTableColumn *column = [[_fileHistoryTableView tableColumns] objectAtIndex:0];
    [column setDataCell:_imageAndTextCell];
    
    NSButtonCell *previewCell = [[[NSButtonCell alloc]init]autorelease];
    [previewCell setBordered:NO];
    [previewCell setImage:[NSImage imageNamed:@"NSRevealFreestandingTemplate"]];
    [previewCell setImageScaling:NSImageScaleProportionallyDown];
    [previewCell setAction:@selector(previewSelectedRow)];
    [previewCell setTitle:@""];
   // [previewCell highlightsBy:NSContentsCellMask];
    previewCell.highlightsBy = NSContentsCellMask;
    NSTableColumn *columnThree = [[_fileHistoryTableView tableColumns] objectAtIndex:1];
    [columnThree setDataCell:previewCell];
    
    NSButtonCell *deleteCell = [[[NSButtonCell alloc]init]autorelease];
    [deleteCell setBordered:NO];
    [deleteCell setImage:[NSImage imageNamed:@"NSStopProgressFreestandingTemplate"]];
    [deleteCell setImageScaling:NSImageScaleProportionallyDown];
    [deleteCell setAction:@selector(deleteSelectedRow)];
    deleteCell.highlightsBy = NSContentsCellMask;
    NSTableColumn *columnTwo = [[_fileHistoryTableView tableColumns] objectAtIndex:2];
    [columnTwo setDataCell:deleteCell];
    
    // Wu:Set the tableview can accept being dragged from
    [_fileHistoryTableView registerForDraggedTypes:[NSArray arrayWithObjects:NSFilesPromisePboardType,NSFilenamesPboardType,NSTIFFPboardType,nil]];
	// Wu:Tell NSTableView we want to drag and drop accross applications the default is YES means can be only interact with current application
	[_fileHistoryTableView setDraggingSourceOperationMask:NSDragOperationCopy forLocal:NO];
}

#pragma mark - Public Method

- (void)showHistoryPopOver:(NSView *)attachedView
{
    // Wu: init the popOver
    if (_historyPopOver == nil) {
        // Create and setup our window
        _historyPopOver = [[NSPopover alloc] init];
        // The popover retains us and we retain the popover. We drop the popover whenever it is closed to avoid a cycle.
        _historyPopOver.contentViewController = self;
        _historyPopOver.behavior = NSPopoverBehaviorTransient;
        _historyPopOver.delegate = self;
    }
    
    if ([_fileHistoryArray count] != 0) {
        [_removeButton setHidden:NO];
    } else
    {
        [_removeButton setHidden:YES];
    }
    // Wu:CGRectMaxXEdge means appear in the right of button
    [_historyPopOver showRelativeToRect:[attachedView bounds] ofView:attachedView preferredEdge:CGRectMinYEdge];
}

#pragma mark - IBAction

- (IBAction)removeAllHistory:(id)sender
{
    if ([_fileHistoryArray count] == 0) {
        return ;
    } else {
        [_fileHistoryArray removeAllObjects];
        [_fileHistoryTableView noteNumberOfRowsChanged];
        [_fileHistoryTableView reloadData];
    }
    
    // Wu:Force it to close
    [_historyPopOver close];
    
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [_fileHistoryArray count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    return [_fileHistoryArray objectAtIndex:rowIndex];
}

- (BOOL)   tableView:(NSTableView *)pTableView 
writeRowsWithIndexes:(NSIndexSet *)pIndexSetOfRows 
		toPasteboard:(NSPasteboard*)pboard
{
	// Wu:This is to allow us to drag files to save
	// We don't do this if more than one row is selected
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
    NSInteger zIndex = [indexSet firstIndex];
    WDMessage *message = [_fileHistoryArray objectAtIndex:zIndex];
    
    NSURL *newURL = [NSURL URLWithString:[NSString stringWithFormat:@"file://%@/%@", 
                                          dropDestination.path, 
                                          [message.fileURL.lastPathComponent stringByReplacingOccurrencesOfString:@" " 
                                                                                                       withString:@"%20"]]];
    
    if (newURL == nil) {
        NSString *escapedString = [self escapedStringFromURL:message.fileURL];
        newURL = [NSURL URLWithString:[NSString stringWithFormat:@"file://%@/%@", 
                                       dropDestination.path, 
                                       [escapedString stringByReplacingOccurrencesOfString:@" " 
                                                                                withString:@"%20"]]];
    } else {
        newURL = [newURL URLWithoutNameConflict];
    }

    NSData *data = [NSData dataWithContentsOfURL:message.fileURL];
    [[NSFileManager defaultManager] createFileAtPath:newURL.path contents:data attributes:nil];
    return [NSArray arrayWithObjects:newURL.lastPathComponent, nil];
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    WDMessage *message = [_fileHistoryArray objectAtIndex:row];
    if (message .type == WDMessageTypeText && tableColumn == [[_fileHistoryTableView tableColumns]objectAtIndex:1])
    {
        NSButtonCell *buttonCell = (NSButtonCell *)cell;
        [buttonCell setImagePosition:NSNoImage];
    }
    else if (message.type == WDMessageTypeFile && tableColumn == [[_fileHistoryTableView tableColumns]objectAtIndex:1])
    {
        NSButtonCell *buttonCell = (NSButtonCell *)cell;
        [buttonCell setImagePosition:NSImageOverlaps];
    }
}

#pragma mark - ImageAndTextCellDelegate

- (NSImage *)previewIconForCell:(NSObject *)data
{
    //DLog(@"previewIconForCell");
    WDMessage *message = (WDMessage *)data;
    if (message.type == WDMessageTypeText){
        return [NSImage imageNamed:@"text"];
    } else if (message.type == WDMessageTypeFile){
        NSImage *icon = [NSImage imageWithPreviewOfFileAtPath:[message.fileURL path] asIcon:YES];
        return icon;
    }
    return nil;
}

- (NSString *)primaryTextForCell:(NSObject *)data
{
    //DLog(@"primaryTextForCell");
    WDMessage *message = (WDMessage *)data;
    if (message.type == WDMessageTypeText){
        NSString *string = [[[NSString alloc]initWithData:message.content encoding:NSUTF8StringEncoding] autorelease];
        if ([string length] >= 20) {
            string = [string substringWithRange:NSMakeRange(0,15)];
            string = [string stringByAppendingString:@"......."];
        }
        return string;
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

- (NSInteger)indexForCell:(NSObject *)data
{
    WDMessage *message = (WDMessage *)data;
    DLog(@"index is %@",[_fileHistoryArray indexOfObject:message]);
    return [_fileHistoryArray indexOfObject:message];
}

#pragma mark - ContextMenuDelegate

- (NSMenu*)tableView:(NSTableView*)aTableView menuForRows:(NSIndexSet*)rows
{
    NSMenu *menu = [[[NSMenu alloc] init] autorelease];
    NSInteger selectedRow = [rows firstIndex];
    WDMessage *message = [_fileHistoryArray objectAtIndex:selectedRow];
    if (message.type == WDMessageTypeText) {
        NSMenuItem *deleteItem = [[NSMenuItem alloc]initWithTitle:@"Delete" action:@selector(deleteSelectedRow) keyEquivalent:@""];
        [menu addItem:deleteItem];
        [deleteItem release];
    } else {
        
        NSMenuItem *previewItem = [[NSMenuItem alloc]initWithTitle:@"Show in Finder" action:@selector(previewSelectedRow) keyEquivalent:@""];
        [menu addItem:previewItem];
        [previewItem release];
        
        NSMenuItem *deleteItem = [[NSMenuItem alloc]initWithTitle:@"Delete" action:@selector(deleteSelectedRow) keyEquivalent:@""];
        [menu addItem:deleteItem];
        [deleteItem release];
        
        NSMenuItem *quicklookItem = [[NSMenuItem alloc]initWithTitle:@"Quicklook" action:@selector(showItPreview) keyEquivalent:@""];
        [menu addItem:quicklookItem];
        [quicklookItem release];
    }
    return menu;
}

@end
