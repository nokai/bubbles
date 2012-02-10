//
//  ImageAndTextCell.m
//  Bubbles
//
//  Created by 吴 wuziqi on 12-2-5.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import "ImageAndTextCell.h"

@implementation ImageAndTextCell

@synthesize previewImage = _previewImage;
@synthesize auxiliaryText = _auxiliaryText;
@synthesize primaryText = _primaryText;
@synthesize fileURL = _fileURL;
@synthesize delegate;

- (void)showItPreview
{
    DLog(@"showfileURl is %@",_fileURL);
    AppDelegate *del = (AppDelegate *)[NSApp delegate];
    if (![del.array containsObject:_fileURL]) {
        del.array = [NSArray arrayWithObject:_fileURL];
    }
    [del showPreviewInHistory];
}

- (void)deleteRows
{
    [self.delegate deleteSeletcedRows];
}

- (void)dealloc
{
    DLog(@"dealloc");
    [_previewButton release];
    [_deleteButton release];
    [_previewImage release];
    [_auxiliaryText release];
    [_primaryText release];
    [_previewImage release];
    [_fileURL release];
    [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone
{
    ImageAndTextCell *cell = (ImageAndTextCell *)[super copyWithZone:zone];
    cell.primaryText = nil;
    cell.auxiliaryText = nil;
    cell.delegate = nil;
    cell.previewImage = nil;
    cell.fileURL = nil;
    return cell;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    [self setTextColor:[NSColor blackColor]];
    
    // Wu:fetch the three attributes 02/05
    NSObject *data = [self objectValue];
    _primaryText = [[self.delegate primaryTextForCell:data] retain];
    _auxiliaryText = [[self.delegate auxiliaryTextForCell:data] retain];
    _previewImage = [[self.delegate previewIconForCell:data] retain];
    _fileURL = [[self.delegate URLForCell:data] retain];
    
    // Wu:For the primaryText 02/05
    NSColor *primartTextColor = [self isHighlighted] ? [NSColor alternateSelectedControlTextColor] : 
    [NSColor textColor];
    NSDictionary *primaryTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:primartTextColor,NSForegroundColorAttributeName,[NSFont systemFontOfSize:13],NSFontAttributeName,nil];
    [_primaryText drawAtPoint:NSMakePoint(cellFrame.origin.x + cellFrame.size.height + 10, cellFrame.origin.y) withAttributes:primaryTextAttributes];
    
    // Wu:For the auxiliaryText 02/05
    NSColor *auxiliaryTextColor = [self isHighlighted] ? [NSColor alternateSelectedControlTextColor] : 
    [NSColor disabledControlTextColor];
    NSDictionary *auxiliaryTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:auxiliaryTextColor,NSForegroundColorAttributeName,[NSFont systemFontOfSize:10],NSFontAttributeName,nil];
    [_auxiliaryText drawAtPoint:NSMakePoint(cellFrame.origin.x + cellFrame.size.height + 10, cellFrame.origin.y +cellFrame.size.height / 2) withAttributes:auxiliaryTextAttributes];
    
    // Wu:For the previewImage
    [[NSGraphicsContext currentContext] saveGraphicsState];
    float yOffset = cellFrame.origin.y;
	if ([controlView isFlipped]) {
		NSAffineTransform* xform = [NSAffineTransform transform];
		[xform translateXBy:0.0 yBy: cellFrame.size.height];
		[xform scaleXBy:1.0 yBy:-1.0];
		[xform concat];		
		yOffset = 0-cellFrame.origin.y;
	}	
	
	NSImageInterpolation interpolation = [[NSGraphicsContext currentContext] imageInterpolation];
	[[NSGraphicsContext currentContext] setImageInterpolation: NSImageInterpolationHigh];	
	
	[_previewImage drawInRect:NSMakeRect(cellFrame.origin.x + 5, yOffset + 3, cellFrame.size.height - 6, cellFrame.size.height - 6) 
                     fromRect:NSMakeRect(0,0,[_previewImage size].width,[_previewImage size].height) 
                    operation:NSCompositeSourceOver
                     fraction:1.0];
	
	[[NSGraphicsContext currentContext] setImageInterpolation: interpolation];
	
	[[NSGraphicsContext currentContext] restoreGraphicsState];	   
    
    // Wu:Set the preview button
    _previewButton = [[NSButton alloc]initWithFrame:CGRectMake(cellFrame.origin.x + 200 ,cellFrame.origin.y , 30, cellFrame.size.height / 2 )];
    [_previewButton setTarget:self];
    [_previewButton setAction:@selector(showItPreview)];
    [_previewButton setBordered:NO];
    [_previewButton setImage:[NSImage imageNamed:@"NSRevealFreestandingTemplate"]];
    [controlView addSubview:_previewButton];
    [_previewButton release];
    
    // Wu:Set the delete button
    
    _deleteButton = [[NSButton alloc]initWithFrame:CGRectMake(cellFrame.origin.x + 170 ,cellFrame.origin.y , 30, cellFrame.size.height / 2 )];
    [_deleteButton setTarget:self];
    [_deleteButton setBordered:NO];
    [_deleteButton setAction:@selector(deleteRows)];
    [_deleteButton setImage:[NSImage imageNamed:@"NSStopProgressTemplate"]];
    [controlView addSubview:_deleteButton];
    [_deleteButton release];
}

@end
