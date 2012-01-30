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
#define kWDMessageFileURL   @"kWDMessageFileURL"
#define kWDMessageContent   @"kWDMessageContent"
#define kWDMessageType      @"kWDMessageType"

@implementation WDMessage
@synthesize sender = _sender, time = _time, fileURL = _fileURL, content = _content, type = _type;

+ (id)messageWithText:(NSString *)text {
    WDMessage *m = [[[WDMessage alloc] init] autorelease];
    m.content = [text dataUsingEncoding:NSUTF8StringEncoding];
    m.time = [NSDate date];
    m.type = WDMessageTypeText;
    DLog(@"WDMessage messageWithText %@", m);
    return m;
}

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
+ (id)messageWithImage:(UIImage *)image {
    WDMessage *m = [[[WDMessage alloc] init] autorelease];
    m.content = UIImagePNGRepresentation(image);
    m.time = [NSDate date];
    m.type = WDMessageTypeImage;
    return m;
}
#elif TARGET_OS_MAC
+ (id)messageWithImage:(NSImage *)image {
    WDMessage *m = [[[WDMessage alloc] init] autorelease];
    m.content = [image TIFFRepresentation];
    m.time = [NSDate date];
    m.type = WDMessageTypeImage;
    return m;
}
#endif

+ (id)messageWithFile:(NSURL *)url {
    WDMessage *m = [[[WDMessage alloc] init] autorelease];
    m.fileURL = url;
    m.content = [NSData dataWithContentsOfURL:url];
    m.time = [NSDate date];
    m.type = WDMessageTypeFile;
    //DLog(@"WDMessage messageWithFile %@", m);
    return m;
}

#pragma mark - Private Methods

- (NSString *)description {
    return [NSString stringWithFormat:@"WDMessage %@, %@, %@, %i", 
            self.fileURL, 
            self.content, 
            self.time, 
            self.type];
}

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:_sender forKey:kWDMessageSender];
    [encoder encodeObject:_time forKey:kWDMessageTime];
    [encoder encodeObject:_fileURL forKey:kWDMessageFileURL];
    [encoder encodeObject:_content forKey:kWDMessageContent];
    [encoder encodeInteger:_type forKey:kWDMessageType];
}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    //_sender = [[decoder decodeObjectForKey:kWDMessageSender] retain];
    _fileURL = [[decoder decodeObjectForKey:kWDMessageFileURL] retain];
    _content = [[decoder decodeObjectForKey:kWDMessageContent] retain];
    _time = [[decoder decodeObjectForKey:kWDMessageTime] retain];
    _type = [decoder decodeIntegerForKey:kWDMessageType];
    return self;
}

@end
