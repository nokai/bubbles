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
@synthesize delegate;

- (void)dealloc
{
    [_previewImage release];
    [_auxiliaryText release];
    [_primaryText release];
    [super dealloc];
}

/*- (id)copyWithZone:(NSZone *)zone
{
    DLog(@"copyWithZone");
    ImageAndTextCell *cell = (ImageAndTextCell *)[super copyWithZone:zone];
    cell.primaryText = nil;
    cell.auxiliaryText = nil;
    cell.delegate = nil;
    cell.previewImage = nil;
    return cell;
}*/

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    DLog(@"drawWithFrame");
    [self setTextColor:[NSColor blackColor]];
    
    // Wu:fetch the three attributes 02/05
    NSObject *data = [self objectValue];
    _primaryText = [self.delegate primaryTextForCell:data];
    _auxiliaryText = [self.delegate auxiliaryTextForCell:data];
    _previewImage = [self.delegate previewIconForCell:data];
    
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
                     fromRect:NSMakeRect(0,0,cellFrame.size.width,cellFrame.size.height) 
                    operation:NSCompositeSourceOver
                     fraction:1.0];
	
	[[NSGraphicsContext currentContext] setImageInterpolation: interpolation];
	
	[[NSGraphicsContext currentContext] restoreGraphicsState];	                                                             
}

@end
