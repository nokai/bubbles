//
//  DWMessage.h
//  bubbles
//
//  Created by 王得希 on 12-7-6.
//  Copyright (c) 2012年 Leavesoft. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DWMessage : NSObject
{
    NSString *_senderName;
    NSString *_senderType;
    NSDate *_time;
    NSString *_state;   // DW: state is used in file transfer
    NSURL *_fileURL;    // DW: available only in file type
    NSData *_content;
}

@property (nonatomic, retain) NSString *senderName;
@property (nonatomic, retain) NSString *senderType;
@property (nonatomic, retain) NSDate *time;
@property (nonatomic, retain) NSString *state;
@property (nonatomic, retain) NSURL *fileURL;
@property (nonatomic, retain) NSData *content;

+ (id)messageWithText:(NSString *)text;
+ (id)messageWithFile:(NSURL *)url andState:(NSString *)state;

- (NSUInteger)fileSize;
- (void)setFileSize:(NSUInteger)fileSize;

@end
