//
//  WDLocalization.h
//  Bubbles
//
//  Created by 王 得希 on 12-3-18.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kActionSheetButtonCopy      [WDLocalization stringForKey:@"kActionSheetButtonCopy"]
#define kActionSheetButtonEmail     [WDLocalization stringForKey:@"kActionSheetButtonEmail"]
#define kActionSheetButtonSend      [WDLocalization stringForKey:@"kActionSheetButtonSend"]
#define kActionSheetButtonMessage   [WDLocalization stringForKey:@"kActionSheetButtonMessage"]
#define kActionSheetButtonPreview   [WDLocalization stringForKey:@"kActionSheetButtonPreview"]
#define kActionSheetButtonSave      [WDLocalization stringForKey:@"kActionSheetButtonSave"]

#define kActionSheetButtonHelpPDF           [WDLocalization stringForKey:@"kActionSheetButtonHelpPDF"]
#define kActionSheetButtonHelpSplash        [WDLocalization stringForKey:@"kActionSheetButtonHelpSplash"]

#define kActionSheetButtonTransferTerminate [WDLocalization stringForKey:@"kActionSheetButtonTransferTerminate"]

#define kActionSheetButtonCancel    [WDLocalization stringForKey:@"kActionSheetButtonCancel"]
#define kActionSheetButtonDeleteAll [WDLocalization stringForKey:@"kActionSheetButtonDeleteAll"]

@interface WDLocalization : NSObject

+ (NSString *)stringForKey:(NSString *)key;

@end
