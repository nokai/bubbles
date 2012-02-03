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
    WDMessageTypeFile
};
typedef NSUInteger WDMessageType;

@interface WDMessage : NSObject <NSCoding> {
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
@property (nonatomic, assign) NSUInteger type;

+ (BOOL)isImageURL:(NSURL *)url;
+ (id)messageWithText:(NSString *)text;
+ (id)messageWithFile:(NSURL *)url;

@end
