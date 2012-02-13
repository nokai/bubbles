//
//  ViewController.h
//  LearnBonjour
//
//  Created by 王 得希 on 12-1-5.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuickLook/QuickLook.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

#import "WDBubble.h"
#import "DirectoryWatcher.h"
#import "PasswordViewController.h"
#import "TextViewController.h"

@interface ViewController : UIViewController <
UIAlertViewDelegate, 
UITextFieldDelegate, 
UINavigationControllerDelegate, 
UIImagePickerControllerDelegate, 
PasswordViewControllerDelegate, 
WDBubbleDelegate, 
TextViewControllerDelegate, 
UITableViewDelegate, 
UITableViewDataSource, 
UIActionSheetDelegate, 
MFMailComposeViewControllerDelegate, 
MFMessageComposeViewControllerDelegate, 
UIDocumentInteractionControllerDelegate, 
DirectoryWatcherDelegate, 
UISplitViewControllerDelegate> {
    // DW: bubbles core
    WDBubble *_bubble;
    NSURL *_fileURL;
    NSMutableArray *_messages;
    
    // DW: files
    NSMutableArray *_documents;
    DirectoryWatcher *_directoryWatcher;
    
    // DW: UI
    NSMutableArray *_itemsToShow;
    NSMutableDictionary *_thumbnails; // DW: key is file url path
    IBOutlet UISegmentedControl *_segmentSwith;
    IBOutlet UITableView *_messagesView;
    IBOutlet UIButton *_lockButton;
    IBOutlet UINavigationBar *_bar;
    IBOutlet UIBarButtonItem *_clearButton;
    
    // DW: password
    PasswordViewController *_passwordViewController;
}

@property (nonatomic, retain) WDBubble *bubble;

- (void)lock;

// DW: it's very weird that sometimes I can't drag actions to this vc unless I declare these methods as public
- (IBAction)sendText:(id)sender;
- (IBAction)selectFile:(id)sender;
- (IBAction)showPeers:(id)sender;
- (IBAction)toggleUsePassword:(id)sender;
- (IBAction)toggleView:(id)sender;
- (IBAction)clearButton:(id)sender;

@end
