//
//  WDMessage.m
//  LearnBonjour
//
//  Created by 王 得希 on 12-1-6.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import "WDMessage.h"

#define kWDMessageSender    @"kWDMessageSender"
#define kWDMessageTime      @"kWDMessageTime"
#define kWDMessageContent   @"kWDMessageContent"
#define kWDMessageType      @"kWDMessageType"

@implementation WDMessage
@synthesize sender, time, content, type;

+ (id)messageWithText:(NSString *)text {
    WDMessage *m = [[WDMessage alloc] init];
    m.content = [text dataUsingEncoding:NSUTF8StringEncoding];
    m.time = [NSDate date];
    m.type = WDMessageTypeText;
    return m;
}

+ (id)messageWithImage:(UIImage *)image {
    WDMessage *m = [[WDMessage alloc] init];
    m.content = UIImagePNGRepresentation(image);
    m.time = [NSDate date];
    m.type = WDMessageTypeImage;
    return m;
}

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.sender forKey:kWDMessageSender];
    [encoder encodeObject:self.time forKey:kWDMessageTime];
    [encoder encodeObject:self.content forKey:kWDMessageContent];
    [encoder encodeInteger:type forKey:kWDMessageType];
}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    self.sender = [decoder decodeObjectForKey:kWDMessageSender];
    self.time = [decoder decodeObjectForKey:kWDMessageTime];
    self.content = [decoder decodeObjectForKey:kWDMessageContent];
    self.type = [decoder decodeIntegerForKey:kWDMessageType];
    return self;
}

@end
