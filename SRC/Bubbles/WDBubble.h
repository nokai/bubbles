//
//  WDBubbleService.h
//  LearnBonjour
//
//  Created by 王 得希 on 12-1-5.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AsyncSocket.h"
#import "WDMessage.h"
#import "WDHeader.h"

@interface NSURL (Bubbles)
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
+ (NSURL *)iOSDocumentsDirectoryURL;
+ (NSString *)iOSDocumentsDirectoryPath;
#elif TARGET_OS_MAC
#endif
+ (NSString *)formattedFileSize:(unsigned long long)size;

- (NSURL *)URLWithRemoteChangedToLocal;
- (NSURL *)URLWithoutNameConflict;
- (NSURL *)UnicodeURLWithoutNameConflict;
- (NSString *)escapedStringFromURL;
@end

@protocol WDBubbleDelegate
- (void)percentUpdated;
- (void)willReceiveMessage:(WDMessage *)message;
- (void)didReceiveMessage:(WDMessage *)message;
- (void)didSendMessage:(WDMessage *)message;
@end

@interface WDBubble : NSObject <AsyncSocketDelegate, NSNetServiceDelegate, NSNetServiceBrowserDelegate, NSStreamDelegate> {
    // DW: Bonjour
    NSNetService    *_service;
    NSNetServiceBrowser *_browser;
    NSMutableArray *_servicesFound;
    NSString *_netServiceType;
    
    // DW: sockets
	AsyncSocket *_socketListen;
    AsyncSocket *_socketReceive;
    NSMutableArray *_socketsConnect;
    
    // DW: Message
    WDMessage *_currentMessage;
    NSMutableData *_dataBuffer;
    
    // DW: stating system
    BOOL _isReceiver;
    // DW: whether it's a receiver or sender during a socket connection
    
    // DW: streamed file read and write
    // sender side stream
    NSInteger _streamBytesRead;
    NSInputStream *_streamFileReader;
    NSMutableData *_streamDataBufferReader;
    // receiver side stream
    NSInteger _streamBytesWrote;
    NSOutputStream *_streamFileWriter;
    NSMutableData *_streamDataBufferWriter;
}

@property (nonatomic, retain) NSNetService *service;
@property (nonatomic, retain) NSArray *servicesFound;
@property (nonatomic, retain) id<WDBubbleDelegate> delegate;

- (void)publishServiceWithPassword:(NSString *)pwd;
- (void)browseServices;
- (void)stopService;

- (void)broadcastMessage:(WDMessage *)message;
- (void)sendMessage:(WDMessage *)message toServiceNamed:(NSString *)name;

// DW: transfer percent, from 0 to 1
- (float)percentTransfered;

@end
