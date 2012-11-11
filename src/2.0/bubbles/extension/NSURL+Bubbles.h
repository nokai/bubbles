//
//  NSURL+Bubbles.h
//  bubbles
//
//  Created by 王得希 on 12-7-6.
//  Copyright (c) 2012年 Leavesoft. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (Bubbles)

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
+ (NSURL *)iOSDocumentsDirectoryURL;
+ (NSString *)iOSDocumentsDirectoryPath;
+ (NSURL *)iOSInboxDirectoryURL;
#elif TARGET_OS_MAC
#endif

+ (NSString *)formattedFileSize:(unsigned long long)size;

- (NSURL *)URLByMovingToParentFolder;
- (NSURL *)URLWithRemoteChangedToLocal;
- (NSURL *)URLWithoutNameConflict;

@end
