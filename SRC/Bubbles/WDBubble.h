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
+ (NSURL *)applicationDocumentsDirectory;
#elif TARGET_OS_MAC
#endif
+ (NSURL *)URLWithSmartConvertionFromURL:(NSURL *)url;
@end
   
@protocol WDBubbleDelegate
- (void)didReceiveMessage:(WDMessage *)message ofText:(NSString *)text;
- (void)didReceiveMessage:(WDMessage *)message ofFile:(NSURL *)url;
@end

@interface WDBubble : NSObject <AsyncSocketDelegate, NSNetServiceDelegate, NSNetServiceBrowserDelegate> {
    // DW: Bonjour
    NSNetService    *_service;
    NSNetServiceBrowser *_browser;
    NSMutableArray *_servicesFound;
    NSString *_netServiceType;
    
    // DW: sockets
	AsyncSocket *_socketListen;
    //AsyncSocket *_socketConnect; // DW: the first connect socket, used to determine local or not
    AsyncSocket *_socketReceive;
    NSMutableArray *_socketsConnect;
    
    // DW: Message
    WDMessage *_currentMessage;
    NSMutableData *_dataBuffer;
    
    // 20120114 DW: timer to check progress
    NSTimer *_timer;
    
    // Wuziqi:Percentage of current exceution
    
    float _pertangeIndicatior;
}

@property (nonatomic, retain) NSNetService *service;
//@property (nonatomic, retain) NSNetServiceBrowser *browser;
//@property (nonatomic, retain) NSString *netServiceType;
//@property (nonatomic, retain) AsyncSocket *socketListen;
//@property (nonatomic, retain) AsyncSocket *socketConnect;
@property (nonatomic, retain) NSArray *servicesFound;
@property (nonatomic, retain) id<WDBubbleDelegate> delegate;
//@property (nonatomic, assign) float percentageIndicator;

- (void)publishServiceWithPassword:(NSString *)pwd;
- (void)browseServices;
- (void)broadcastMessage:(WDMessage *)msg;
- (void)stopService;

@end
