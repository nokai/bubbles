//
//  DragAndDropImageView.m
//  Bubbles
//
//  Created by 吴 wuziqi on 12-1-15.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import "DragAndDropImageView.h"

@implementation DragAndDropImageView

@synthesize delegate;

NSString *kPrivateDragUTI = @"com.yourcompany.cocoadraganddrop";

#pragma mark - Lifecycle

- (id)initWithCoder:(NSCoder *)coder
{
    self=[super initWithCoder:coder];
    if ( self ) {
        
        //register for all the image types we can display
        [self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType,NSTIFFPboardType,nil]];
    }
    return self;
}

- (void)dealloc
{
    [self unregisterDraggedTypes];
    [super dealloc];
}

#pragma mark - Destination Operations : Allow for drag in

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    DLog(@"entered");
    if (([sender draggingSourceOperationMask] & NSDragOperationCopy) == NSDragOperationCopy) {
        
        //Wu:Means we offer the type the destination accepts
        return NSDragOperationCopy;
    }
    
    return NSDragOperationNone;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
    DLog(@"haha exited!!!!!!!!!!!");
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
    return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    
    NSPasteboard *pboard = [sender draggingPasteboard];
	
    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
		//  NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
        //DLog(@"%@", files);
        // Perform operation using the list of files
    }
    
    //Wu:Set the files that can be accepted by NSImageView
    NSPasteboard *pasterboard = [sender draggingPasteboard];
    NSArray *allowedTypes = [NSArray arrayWithObjects:NSFilenamesPboardType,NSTIFFPboardType,nil];
    NSString *fileType = [pasterboard availableTypeFromArray:allowedTypes];
    NSData *data = [pasterboard dataForType:fileType];
    
    NSURL *fileUrl = [NSURL URLFromPasteboard: [sender draggingPasteboard]];
    
    if (data == nil) {
        NSRunAlertPanel(@"Paste Error", @"The operation failed", @"Ok", nil, nil);
        return NO;
    } else {
        if ([fileType isEqualToString:NSPasteboardTypeTIFF]) {
            //Wu:It means it's image ,just paste it and show the preview
            NSImage *image = [[NSImage alloc]initWithData:data];
            [self setImage:image];
            [image release];
            
        }else if ([fileType isEqualToString:NSFilenamesPboardType]){
            //Wu:Other file ,we just show the quicklook of the file
            NSArray *fileAttirbutes = [pasterboard propertyListForType:@"NSFilenamesPboardType"];
            
            //The first is the path of the file
            NSString *filePath = [fileAttirbutes objectAtIndex:0];
            
            NSImage *quicklook = [NSImage imageWithPreviewOfFileAtPath:filePath asIcon:YES];
            [self setImage:quicklook];
            //[quicklook release];
        }else{
            DLog(@"Something error");
        }
    }
    DLog(@"self.delegate is %@",self.delegate);
    [self.delegate dragDidFinished:fileUrl];
    [self setNeedsDisplay:YES];//Wu:Redraw at once
    return YES;
}

/*- (NSRect)windowWillUseStandardFrame:(NSWindow *)window defaultFrame:(NSRect)newFrame
 {
 NSRect ContentRect=self.window.frame;
 
 //set it to the image frame size
 ContentRect.size = [[self image] size];
 
 return [NSWindow frameRectForContentRect:ContentRect styleMask: [window styleMask]];
 }*/

#pragma mark - Source Operations

- (void)mouseDown:(NSEvent*)event
{
    
    NSPoint dragPosition;
    NSRect imageLocation;
    
    dragPosition = [self convertPoint:[event locationInWindow] fromView:nil];
    dragPosition.x -= 16;
    dragPosition.y -= 16;
    imageLocation.origin = dragPosition;
    imageLocation.size = NSMakeSize(32,32);
    [self dragPromisedFilesOfTypes:[NSArray arrayWithObjects:NSFilenamesPboardType,NSTIFFPboardType,nil] 
                          fromRect:imageLocation source:self slideBack:YES event:event];
}

- (void)dragImage:(NSImage *)anImage at:(NSPoint)viewLocation offset:(NSSize)initialOffset event:(NSEvent *)event pasteboard:(NSPasteboard *)pboard source:(id)sourceObj slideBack:(BOOL)slideFlag
{
    if ([self image] == nil) {
        return ;
    }
    // Wu: create a new image for our semi-transparent drag image
    NSImage* dragImage=[[NSImage alloc] initWithSize:[[self image] size]]; 
    
    // DW: this makes dragging visible
    [dragImage lockFocus];// draw inside of our dragImage
    // Wu: draw our original image as 50% transparent
    [[self image] dissolveToPoint: NSZeroPoint fraction: .5];
    [dragImage unlockFocus];// finished drawing
    [dragImage setScalesWhenResized:NO];// we want the image to resize
    //[dragImage setSize:[self bounds].size];// change to the size we are displaying
    
    [super dragImage:dragImage at:self.bounds.origin offset:NSZeroSize event:event pasteboard:pboard source:sourceObj slideBack:slideFlag];
    [dragImage release];
}

// Wu: drag to save, dropDestination is destination, draggedDataURL is source
- (NSArray *)namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination {
    NSURL *draggedDataURL = [self.delegate dataDraggedToSave];
    if (draggedDataURL == nil) {
        return nil;
    }
    
    NSURL *newURL = [[NSURL URLWithString:[draggedDataURL.lastPathComponent stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] 
                            relativeToURL:dropDestination] URLWithoutNameConflict];
    [[NSFileManager defaultManager] copyItemAtURL:draggedDataURL toURL:newURL error:nil];
    
    return [NSArray arrayWithObjects:newURL.lastPathComponent, nil];
}

- (NSDragOperation)draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context
{
    switch (context) {
        case NSDraggingContextOutsideApplication:
            return NSDragOperationCopy;
            
        case NSDraggingContextWithinApplication:
            
        default:
            return NSDragOperationCopy;
            break;
    }
}

//like qq ,the chosen windows do not have to be active
- (BOOL)acceptsFirstMouse:(NSEvent *)event 
{
    return YES;
}

/*- (void)pasteboard:(NSPasteboard *)sender item:(NSPasteboardItem *)item provideDataForType:(NSString *)type
 {
 if ( [type compare: NSPasteboardTypeTIFF] == NSOrderedSame ) {
 
 //set data for TIFF type on the pasteboard as requested
 [sender setData:[[self image] TIFFRepresentation] forType:NSPasteboardTypeTIFF];
 
 } else if ( [type compare: NSFilenamesPboardType] == NSOrderedSame ) {
 
 //set data for Other type on the pasteboard as requested
 [sender setData:[self dataWithPDFInsideRect:[self bounds]] forType:NSPasteboardTypePDF];
 }
 }*/
@end
