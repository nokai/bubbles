//
//  DWBubble.h
//  bubbles
//
//  Created by 王得希 on 12-7-6.
//  Copyright (c) 2012年 Leavesoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DWMessage.h"

@interface DWBubble : NSObject

- (void)publishServiceWithPassword:(NSString *)pwd;
- (void)browseServices;
- (void)stopService;

- (void)sendMessage:(DWMessage *)message toServiceNamed:(NSString *)name;

@end
