//
//  PreferenceViewContoller.m
//  Bubbles
//
//  Created by 吴 wuziqi on 12-1-20.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import "PreferenceViewContoller.h"

#define kGeneralIdentifier @"GeneralIdentifier"

@implementation PreferenceViewContoller

- (id)init {
    if (self = [super initWithWindowNibName:@"PreferenceViewController"]) {
        
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

- (void)awakeFromNib
{
    NSImage *folderIcon = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericFolderIcon)];
    [folderIcon setScalesWhenResized:YES];
    [folderIcon setSize:NSMakeSize(16, 16)];
    NSString *string = [[[NSUserDefaults standardUserDefaults] URLForKey:kUserDefaultMacSavingPath]lastPathComponent];
    [_savePathButton addItemWithTitle:string];
    [[_savePathButton itemAtIndex:0] setImage:folderIcon];
    [[_savePathButton menu] addItem:[NSMenuItem separatorItem]];
    [_savePathButton addItemWithTitle:@"Other..."];
    
    [_toolBar setSelectedItemIdentifier:kGeneralIdentifier];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    //DLog(@"haha is %@",[_savePathButton numberOfItems]);
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)dealloc
{
    [super dealloc];
}

#pragma mark - IBAction

- (IBAction)choosePopUp:(NSPopUpButton *)sender
{
    if ([sender indexOfItem:[sender selectedItem]] == 2) {
        NSOpenPanel *openPanel = [NSOpenPanel openPanel];
        [openPanel setCanChooseFiles:NO];
        [openPanel setCanChooseDirectories:YES];
        
        if ([openPanel runModal] == NSFileHandlingPanelOKButton) {
            
            NSURL *url = [openPanel URL];
            NSImage *folderIcon = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericFolderIcon)];
            [[NSUserDefaults standardUserDefaults] setURL:url forKey:kUserDefaultMacSavingPath];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [_savePathButton insertItemWithTitle:[url lastPathComponent] atIndex:0];
            [[_savePathButton itemAtIndex:0] setImage:folderIcon];
            [_savePathButton selectItemAtIndex:0];
            [_savePathButton removeItemAtIndex:1];
            
        } else{
            [_savePathButton selectItemAtIndex:0];  
        }
    }
}

#pragma mark - NSToolbarItem

-(NSArray*) toolbarSelectableItemIdentifiers: (NSToolbar*)toolbar
{
	return [NSArray arrayWithObjects:kGeneralIdentifier,nil];
}



@end
