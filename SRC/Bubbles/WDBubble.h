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

// DW: network
#define kWDBubbleWebServiceType @"_bubbles._tcp."
#define kWDBubbleInitialDomain  @""
#define kWDBubbleTimeOut        5

// DW: notifications
#define kWDBubbleNotification   @"kWDBubbleNotification"

@protocol WDBubbleDelegate
- (void)didReceiveText:(NSString *)text;
- (void)didReceiveImage:(UIImage *)image;
@end

@interface WDBubble : NSObject <AsyncSocketDelegate, NSNetServiceDelegate, NSNetServiceBrowserDelegate> {
    // DW: Bonjour
    NSNetService    *_service;
    NSNetServiceBrowser *_browser;
    NSMutableArray *_servicesFound;
    
    // DW: sockets
	AsyncSocket *_socketListen;
    AsyncSocket *_socketSender;

    // DW: Message
    WDMessage *_currentMessage;
    NSMutableData *_dataBuffer;
}

@property (nonatomic, retain) NSNetService *service;
@property (nonatomic, retain) NSNetServiceBrowser *browser;
@property (nonatomic, retain) AsyncSocket *socketListen;
@property (nonatomic, retain) AsyncSocket *socketSender;
@property (nonatomic, retain) NSArray *servicesFound;
@property (nonatomic, retain) id<WDBubbleDelegate> delegate;

- (void)initSocket;
- (void)publishService;
- (void)browseServices;
- (void)broadcastMessage:(WDMessage *)msg;

@end
