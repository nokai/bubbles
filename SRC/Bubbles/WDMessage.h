//
//  WDMessage.h
//  LearnBonjour
//
//  Created by 王 得希 on 12-1-6.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import <Foundation/Foundation.h>

enum {
    WDMessageTypeText, 
    WDMessageTypeFile, 
    WDMessageTypeControl
};
typedef NSUInteger WDMessageType;

// DW: we use these keys as control commands as well as bubble states
#define kWDMessageControlText           @"kWDMessageControlText"
#define kWDMessageControlBegin          @"kWDMessageControlBegin"
#define kWDMessageControlReady          @"kWDMessageControlReady"
#define kWDMessageControlTransfering    @"kWDMessageControlTransfering"
#define kWDMessageControlEnd            @"kWDMessageControlEnd"

@interface WDMessage : NSObject <NSCoding,NSCopying> {
    NSString *_sender;
    NSDate *_time;
    NSURL *_fileURL;    // DW: available only in file type
    NSData *_content;
    NSUInteger _type;
}

@property (nonatomic, retain) NSString *sender;
@property (nonatomic, retain) NSDate *time;
@property (nonatomic, retain) NSURL *fileURL;
@property (nonatomic, retain) NSData *content;
@property (nonatomic, assign) WDMessageType type;

+ (BOOL)isImageURL:(NSURL *)url;
+ (id)messageWithText:(NSString *)text;
+ (id)messageWithFile:(NSURL *)url;
+ (id)messageWithFile:(NSURL *)url andCommand:(NSString *)command;
+ (id)messageInfoFromMessage:(WDMessage *)message;

@end
