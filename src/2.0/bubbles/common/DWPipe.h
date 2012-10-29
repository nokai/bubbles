//
//  DWPipe.h
//  bubbles
//
//  Created by 王得希 on 12-7-6.
//  Copyright (c) 2012年 Leavesoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DWMessage.h"

@protocol DWPipeDelegate
- (void)percentUpdated;
- (void)errorOccured:(NSError *)error;

- (void)willReceiveMessage:(DWMessage *)message;
- (void)didReceiveMessage:(DWMessage *)message;
- (void)didSendMessage:(DWMessage *)message;
- (void)didTerminateReceiveMessage:(DWMessage *)message;
- (void)didTerminateSendMessage:(DWMessage *)message;
@end

@interface DWPipe : NSObject

// DW: transfer control
- (BOOL)isBusy;
- (float)percentTransfered;
- (NSUInteger)bytesTransfered;
- (void)terminateTransfer;

@end
