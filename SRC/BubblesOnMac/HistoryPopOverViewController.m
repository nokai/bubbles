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
- (void)showItPreview:(NSURL *)aFileURL
{
    AppDelegate *del = (AppDelegate *)[NSApp delegate];
    if (![del.array containsObject:aFileURL]) {
        del.array = [NSArray arrayWithObject:aFileURL];
    }
    [del showPreviewInHistory];
}

- (void)deleteSelectedRow
{
    if (0 <= [_fileHistoryTableView selectedRow] && [_fileHistoryTableView selectedRow] < [_fileHistoryArray count]) {
        [_fileHistoryArray removeObjectAtIndex:[_fileHistoryTableView selectedRow]];
    }
    [_fileHistoryTableView reloadData];
}

- (void)previewSelectedRow
{
    if (0 <= [_fileHistoryTableView selectedRow] && [_fileHistoryTableView selectedRow] < [_fileHistoryArray count]) {
        WDMessage *message = (WDMessage *)[_fileHistoryArray objectAtIndex:[_fileHistoryTableView selectedRow]];
        [self showItPreview:message.fileURL];
    }
}

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
    
    NSButtonCell *deleteCell = [[[NSButtonCell alloc]init]autorelease];
    [deleteCell setBordered:NO];
    [deleteCell setImage:[NSImage imageNamed:@"NSStopProgressTemplate"]];
    [deleteCell setAction:@selector(deleteSelectedRow)];
     NSTableColumn *columnTwo = [[_fileHistoryTableView tableColumns] objectAtIndex:1];
    [columnTwo setDataCell:deleteCell];
    
    NSButtonCell *previewCell = [[[NSButtonCell alloc]init]autorelease];
    [previewCell setBordered:NO];
    [previewCell setImage:[NSImage imageNamed:@"NSRevealFreestandingTemplate"]];
    [previewCell setAction:@selector(previewSelectedRow)];
    NSTableColumn *columnThree = [[_fileHistoryTableView tableColumns] objectAtIndex:2];
    [columnThree setDataCell:previewCell];
    
    
    // Wu:Set the tableview can accept being dragged from
    [_fileHistoryTableView registerForDraggedTypes:[NSArray arrayWithObjects:NSFilesPromisePboardType,NSFilenamesPboardType,NSTIFFPboardType,nil]];
	// Wu:Tell NSTableView we want to drag and drop accross applications the default is YES means can be only interact with current application
	[_fileHistoryTableView setDraggingSourceOperationMask:NSDragOperationCopy forLocal:NO];
}

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
    newURL = [newURL URLWithoutNameConflict];
    NSData *data = [NSData dataWithContentsOfURL:message.fileURL];
    [[NSFileManager defaultManager] createFileAtPath:newURL.path contents:data attributes:nil];
    return [NSArray arrayWithObjects:newURL.lastPathComponent, nil];
}

#pragma mark - ImageAndTextCellDelegate

- (NSImage *)previewIconForCell:(NSObject *)data
{
    DLog(@"previewIconForCell");
    WDMessage *message = (WDMessage *)data;
    if (message.type == WDMessageTypeText){
        return nil;
    } else if (message.type == WDMessageTypeFile){
        NSImage *icon = [NSImage imageWithPreviewOfFileAtPath:[message.fileURL path] asIcon:YES];
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

- (NSInteger)indexForCell:(NSObject *)data
{
    WDMessage *message = (WDMessage *)data;
    DLog(@"index is %@",[_fileHistoryArray indexOfObject:message]);
    return [_fileHistoryArray indexOfObject:message];
}

@end
