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

// DW: states actually
#define kWDMessageControlText           @"kWDMessageControlText"
#define kWDMessageControlBegin          @"kWDMessageControlBegin"
#define kWDMessageControlReady          @"kWDMessageControlReady"
#define kWDMessageControlTransfering    @"kWDMessageControlTransfering"

@interface WDMessage : NSObject <NSCoding,NSCopying> {
    NSString *_sender;
    NSDate *_time;
    NSString *_state;   // DW: state is used in file transfer
    NSURL *_fileURL;    // DW: available only in file type
    NSData *_content;
    NSUInteger _type;
}

@property (nonatomic, retain) NSString *sender;
@property (nonatomic, retain) NSDate *time;
@property (nonatomic, retain) NSString *state;
@property (nonatomic, retain) NSURL *fileURL;
@property (nonatomic, retain) NSData *content;
@property (nonatomic, assign) WDMessageType type;

+ (BOOL)isImageURL:(NSURL *)url;
+ (id)messageWithText:(NSString *)text;
+ (id)messageWithFile:(NSURL *)url;
+ (id)messageWithFile:(NSURL *)url andState:(NSString *)state;
+ (id)messageInfoFromMessage:(WDMessage *)message;

- (NSUInteger)fileSize;
- (void)setFileSize:(NSUInteger)fileSize;

@end
