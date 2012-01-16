//
//  DragAndDropImageView.h
//  Bubbles
//
//  Created by 吴 wuziqi on 12-1-15.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DragAndDropImageView : NSImageView <NSDraggingSource, NSDraggingDestination, NSPasteboardItemDataProvider> {
    
}

- (id)initWithCoder:(NSCoder *)coder;

@end
