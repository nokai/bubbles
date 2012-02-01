//
//  TextViewController.m
//  Bubbles
//
//  Created by 王 得希 on 12-2-1.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import "TextViewController.h"

@implementation TextViewController
@synthesize undoManager = _undoManager, delegate;

// Call this method somewhere in your view controller setup code.
- (void)registerForKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
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

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    // DW: custom bar bg
    // this will appear as the title in the navigation bar
    UILabel *label = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont boldSystemFontOfSize:20.0];
    label.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    label.textAlignment = UITextAlignmentCenter;
    label.textColor = [UIColor colorWithWhite:0.5 alpha:1];
    self.navigationItem.titleView = label;
    label.text = NSLocalizedString(@"Peers", @"");
    [label sizeToFit];
    if ([self.navigationController.navigationBar respondsToSelector:@selector(setBackgroundImage:forBarMetrics:)]) {
        [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"tile_bg"]
                                                      forBarMetrics:UIBarMetricsDefault];
    }
    
    self.navigationItem.rightBarButtonItem = _done;
        self.navigationItem.leftBarButtonItem = _cancel;
    [self registerForKeyboardNotifications];    
    [self setUpUndoManager];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    [self cleanUpUndoManager];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - IBActions

- (IBAction)cancelEditing:(id)sender {
    [_textView resignFirstResponder];
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)doneEditing:(id)sender {
    //self.navigationItem.rightBarButtonItem = nil;
    [_textView resignFirstResponder];
    [self.delegate didFinishWithText:_textView.text];
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - UITextViewDelegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    //self.navigationItem.rightBarButtonItem = _done;
    //[self.navigationItem setHidesBackButton:YES animated:YES];
    return YES;
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
    //[_textView resignFirstResponder];
    //[self performSelector:@selector(keyboardWillBeHidden:) withObject:nil];
    [self.navigationItem setHidesBackButton:NO animated:YES];
    return YES;
}

#pragma mark - Undo support

- (void)setUpUndoManager {
	/*
	 If the diary's managed object context doesn't already have an undo manager, then create one and set it for the context and self.
	 The view controller needs to keep a reference to the undo manager it creates so that it can determine whether to remove the undo manager when editing finishes.
	 */
    NSUndoManager *anUndoManager = [[NSUndoManager alloc] init];
    [anUndoManager setLevelsOfUndo:3];
    self.undoManager = anUndoManager;
    [anUndoManager release];
	
	// Register as an observer of the diary's context's undo manager.
	NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
	[dnc addObserver:self selector:@selector(undoManagerDidUndo:) name:NSUndoManagerDidUndoChangeNotification object:anUndoManager];
	[dnc addObserver:self selector:@selector(undoManagerDidRedo:) name:NSUndoManagerDidRedoChangeNotification object:anUndoManager];
}

- (void)cleanUpUndoManager {
	
	// Remove self as an observer.
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    self.undoManager = nil;
}

- (NSUndoManager *)undoManager {
	return _undoManager;
}

- (void)undoManagerDidUndo:(NSNotification *)notification {
	//[self updateRightBarButtonItemState];
}


- (void)undoManagerDidRedo:(NSNotification *)notification {
	//[self updateRightBarButtonItemState];
}

/*
 The view controller must be first responder in order to be able to receive shake events for undo. It should resign first responder status when it disappears.
 */
- (BOOL)canBecomeFirstResponder {
	return YES;
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[self becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[self resignFirstResponder];
}

#pragma mark - Keyboard

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification {
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    NSLog(@"kbh %f, %f", kbSize.width, kbSize.height);
    UIEdgeInsets contentInsets;
    if (self.interfaceOrientation == UIInterfaceOrientationPortrait) {
        contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    } else {
        contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.width, 0.0);
    }
    
    _textView.contentInset = contentInsets;
    _textView.scrollIndicatorInsets = contentInsets;
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification {
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    _textView.contentInset = contentInsets;
    _textView.scrollIndicatorInsets = contentInsets;
}

@end
