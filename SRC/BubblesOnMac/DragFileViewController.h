//
//  DragFileViewController.h
//  Bubbles
//
//  Created by 吴 wuziqi on 12-2-8.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DragAndDropImageView.h"

@interface DragFileViewController : NSViewController
{
    IBOutlet DragAndDropImageView *_imageView;
}
@property (nonatomic ,retain) IBOutlet DragAndDropImageView *imageView;
@end
