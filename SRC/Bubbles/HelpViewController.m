//
//  HelpViewController.m
//  Bubbles
//
//  Created by 王 得希 on 12-2-16.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import "HelpViewController.h"
#import "WDHeader.h"

#define kNumberOfPages  7

@implementation HelpViewController
@synthesize helpPages = _helpPages, helpPageControl = _helpPageControl;

- (void)loadScrollViewWithPage:(int)page
{
    if (page < 0)
        return;
    if (page >= kNumberOfPages)
        return;
    
    UIImageView *t = [[UIImageView alloc] initWithImage:
                      [UIImage imageNamed:
                       [NSString stringWithFormat:@"help%i%i.png", 
                        [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad, page+1]]];
    CGRect frame = _helpPages.frame;
    frame.origin.x = frame.size.width * page;
    frame.origin.y = 0;
    t.frame = frame;
    [_helpPages addSubview:t];
    [t release];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc {
    [_helpPages release];
    [_helpPageControl release];
    
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    // a page is the width of the scroll view
    _helpPages.pagingEnabled = YES;
    _helpPages.contentSize = CGSizeMake(_helpPages.frame.size.width * kNumberOfPages, _helpPages.frame.size.height);
    _helpPages.showsHorizontalScrollIndicator = NO;
    _helpPages.showsVerticalScrollIndicator = NO;
    _helpPages.scrollsToTop = NO;
    _helpPages.delegate = self;
    
    [UIApplication sharedApplication].statusBarHidden = YES;
    
    for (int i = 0; i < kNumberOfPages; i++) {
        [self loadScrollViewWithPage:i];
    }
    
    _helpPageControl.numberOfPages = kNumberOfPages-1;
    _helpPageControl.currentPage = 0;
    
    // DW: register rotation event
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didRotate:)
                                                 name:@"UIDeviceOrientationDidChangeNotification" 
                                               object:nil];
    
    // DW: rotate view if needed
    if ([UIDevice currentDevice].orientation == UIInterfaceOrientationLandscapeLeft) {
        self.view.transform = CGAffineTransformMakeRotation(M_PI_2);
    } else if ([UIDevice currentDevice].orientation == UIInterfaceOrientationLandscapeRight) {
        self.view.transform = CGAffineTransformMakeRotation(M_PI_2*3);
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    
}

- (void)didRotate:(NSNotification *)notification{  
    // DW: rotate view if needed
    if ([UIDevice currentDevice].orientation == UIInterfaceOrientationLandscapeLeft) {
        self.view.transform = CGAffineTransformMakeRotation(M_PI_2);
    } else if ([UIDevice currentDevice].orientation == UIInterfaceOrientationLandscapeRight) {
        self.view.transform = CGAffineTransformMakeRotation(M_PI_2*3);
    }
} 

#pragma mark - IBActions

- (IBAction)changePage:(id)sender {
    int page = _helpPageControl.currentPage;
    
	// update the scroll view to the appropriate page
    CGRect frame = _helpPages.frame;
    frame.origin.x = frame.size.width * page;
    frame.origin.y = 0;
    [_helpPages scrollRectToVisible:frame animated:YES];
    
	// Set the boolean used when scrolls originate from the UIPageControl. See scrollViewDidScroll: above.
    pageControlUsed = YES;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)sender {
    // We don't want a "feedback loop" between the UIPageControl and the scroll delegate in
    // which a scroll event generated from the user hitting the page control triggers updates from
    // the delegate method. We use a boolean to disable the delegate logic when the page control is used.
    if (pageControlUsed) {
        // do nothing - the scroll was initiated from the page control, not the user dragging
        return;
    }
	
    // Switch the indicator when more than 50% of the previous/next page is visible
    CGFloat pageWidth = _helpPages.frame.size.width;
    int page = floor((_helpPages.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    _helpPageControl.currentPage = page;
    
    // DW: quit on last scroll
    if (page >= kNumberOfPages-1) {
        [UIApplication sharedApplication].statusBarHidden = NO;
        [self.view removeFromSuperview];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kUserDefaultsShouldShowHelp];
    }
    // load the visible page and the page on either side of it (to avoid flashes when the user starts scrolling)
    //[self loadScrollViewWithPage:page - 1];
    //[self loadScrollViewWithPage:page];
    //[self loadScrollViewWithPage:page + 1];
    
    // A possible optimization would be to unload the views+controllers which are no longer visible
}

// At the begin of scroll dragging, reset the boolean used when scrolls originate from the UIPageControl
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    pageControlUsed = NO;
}

// At the end of scroll animation, reset the boolean used when scrolls originate from the UIPageControl
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    pageControlUsed = NO;
}

@end
