//
//  FeatureWindowController.h
//  Bubbles
//
//  Created by 吴 wuziqi on 12-2-25.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSPageControl.h"
#import "DuxScrollViewAnimation.h"
#define kPagenumber 5
#define kViewWidth 380
#define kViewHeight 189

@interface FeatureWindowController : NSWindowController
{
    IBOutlet NSPageControl *_pageControl;
    IBOutlet NSView *_pageTwo;
    int _currentPage;
    
    IBOutlet NSScrollView *_scrollView;
    
    IBOutlet NSButton *_rightButton;
}

@end
