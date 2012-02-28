//
//  PeersViewController.m
//  Bubbles
//
//  Created by 王 得希 on 12-1-9.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import "PeersViewController.h"

@implementation PeersViewController
@synthesize selectedServiceName = _selectedServiceName, dismissButton, lockButton, bubble = _bubble, delegate;

- (void)refreshLockStatus {
    BOOL usePassword = [[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaultsUsePassword];
    if (usePassword) {
        self.lockButton.image = [UIImage imageNamed:@"lock_on"];
    } else {
        self.lockButton.image = [UIImage imageNamed:@"lock_off"];
    }
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
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
    
    // DW: custom bar bg
    // this will appear as the title in the navigation bar
    self.title = @"Peers";
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        self.navigationItem.leftBarButtonItem = self.lockButton;
    } else if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        self.navigationItem.rightBarButtonItem = self.dismissButton;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(servicesUpdated:) 
                                                 name:kWDBubbleNotificationServiceUpdated
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(didEndLock:) 
                                                 name:kWDBubbleNotificationDidEndLock
                                               object:nil];
    
    [self refreshLockStatus];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) || (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.bubble.servicesFound.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell...
    NSNetService *t = [self.bubble.servicesFound objectAtIndex:indexPath.row];
    
    if ([t.name isEqualToString:self.bubble.service.name]) {
        cell.textLabel.text = [t.name stringByAppendingString:@" (local)"];
    } else {
        cell.textLabel.text = t.name;
    }
    
    if ([t.name isEqualToString:self.selectedServiceName]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    cell.imageView.image = [UIImage imageNamed:[WDBubble platformForNetService:t]];
    
    return cell;
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }   
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }   
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Configure the cell...
    NSNetService *t = [self.bubble.servicesFound objectAtIndex:indexPath.row];
    if ([t.name isEqualToString:self.bubble.service.name]) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    } 
    self.selectedServiceName = t.name;
    [tableView reloadData];
}

#pragma mark - IBOutlets

- (IBAction)dismiss:(id)sender {
    [self.delegate didSelectServiceName:self.selectedServiceName];
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)toggleUsePassword:(id)sender {
    BOOL usePassword = [[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaultsUsePassword];
    usePassword = !usePassword;
    
    if (usePassword) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kWDBubbleNotificationShouldLock object:nil];
    } else {
        // DW: unlock
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kUserDefaultsUsePassword];
        [_bubble stopService];
        [_bubble publishServiceWithPassword:@""];
        [_bubble browseServices];
    }
    [self refreshLockStatus];
}

#pragma mark - NC

- (void)servicesUpdated:(NSNotification *)notification {
    [self.tableView reloadData];
}

- (void)didEndLock:(NSNotification *)notification {
    [self refreshLockStatus];
}

@end
