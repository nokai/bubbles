//
//  FeatureWindowController.m
//  Bubbles
//
//  Created by 吴 wuziqi on 12-2-25.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import "FeatureWindowController.h"

@implementation FeatureWindowController

- (id)init
{
    self = [super initWithWindowNibName:@"FeatureWindowController"];
    if (self) {
        _currentPage = 0;
    }
    return self;
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    [_pageControl setType:NSPageControlTypeOnFullOffFull];
    [_pageControl setNumberOfPages:kPagenumber];
    [_scrollView setDocumentView:_pageTwo];
    
    NSRect scrollViewFrame = _scrollView.frame;
    CGPoint originPoint = scrollViewFrame.origin;
    CGSize size = scrollViewFrame.size;
    
    _rightButton.frame = NSMakeRect(originPoint.x + size.width - 32 , size.height / 2 ,32, 32);
    _pageControl.frame = NSMakeRect(originPoint.x + size.width / 2 , size.height - 48,163 , 96);
    
    [_scrollView addSubview:_pageControl];
    [_scrollView addSubview:_rightButton];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)dealloc
{
    [_pageTwo removeFromSuperview];
    [_pageTwo release];
    [super dealloc];
}

#pragma mark - IBAction

- (IBAction)goNextPage:(id)sender
{
    [_pageControl setCurrentPage:++_currentPage];
    [DuxScrollViewAnimation animatedScrollToPoint:NSMakePoint(kViewWidth * _currentPage, 0) inScrollView:_scrollView];
    //[[_scrollView documentView] scrollPoint:NSMakePoint(kViewWidth * _currentPage, 0)];
}

- (IBAction)goPreviousPage:(id)sender
{
    [_pageControl setCurrentPage:--_currentPage];
    
}

@end
