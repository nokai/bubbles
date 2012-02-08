//
//  TextViewController.h
//  Bubbles
//
//  Created by 吴 wuziqi on 12-2-8.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TextViewController : NSViewController
{
    IBOutlet NSTextField *_textField;
}

@property (nonatomic ,retain)IBOutlet NSTextField *textField;

@end
