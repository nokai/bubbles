//
//  DWPipe.m
//  bubbles
//
//  Created by 王得希 on 12-7-6.
//  Copyright (c) 2012年 Leavesoft. All rights reserved.
//

#import "DWPipe.h"

@implementation DWPipe

#pragma mark - Public Methods

- (BOOL)isBusy {
    return YES;
}

- (float)percentTransfered {
    return 0;
}

- (NSUInteger)bytesTransfered {
    return 0;
}

- (void)terminateTransfer {
    
}

@end
