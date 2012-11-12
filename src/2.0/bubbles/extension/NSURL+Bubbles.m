//
//  NSURL+Bubbles.m
//  bubbles
//
//  Created by 王得希 on 12-7-6.
//  Copyright (c) 2012年 Leavesoft. All rights reserved.
//

#import "NSURL+Bubbles.h"

@implementation NSURL (Bubbles)

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATO

+ (NSURL *)iOSDocumentsDirectoryURL {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

+ (NSString *)iOSDocumentsDirectoryPath {
    return [[NSURL iOSDocumentsDirectoryURL] path];
}

+ (NSURL *)iOSInboxDirectoryURL {
    return [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/Inbox", [NSURL iOSDocumentsDirectoryURL].path]];
}

#elif TARGET_OS_MAC
#endif

+ (NSString *)formattedFileSize:(unsigned long long)size {
	NSString *formattedStr = nil;
    if (size == 0)
		formattedStr = @"Empty";
	else
		if (size > 0 && size < 1024)
			formattedStr = [NSString stringWithFormat:@"%qu B", size];
        else
            if (size >= 1024 && size < pow(1024, 2))
                formattedStr = [NSString stringWithFormat:@"%.1f KB", (size / 1024.)];
            else
                if (size >= pow(1024, 2) && size < pow(1024, 3))
                    formattedStr = [NSString stringWithFormat:@"%.2f MB", (size / pow(1024, 2))];
                else
                    if (size >= pow(1024, 3))
                        formattedStr = [NSString stringWithFormat:@"%.3f GB", (size / pow(1024, 3))];
	
	return formattedStr;
}

- (NSURL *)URLWithRemoteChangedToLocal {
    NSString *currentFileName = [[self URLByDeletingPathExtension].lastPathComponent stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
    NSURL *storeURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@.%@",
                                            [[NSURL iOSDocumentsDirectoryURL] absoluteString],
                                            currentFileName,
                                            [[self pathExtension] lowercaseString]]];
#elif TARGET_OS_MAC
    NSURL *defaultURL = [NSURL URLWithString:[[NSUserDefaults standardUserDefaults] stringForKey:kUserDefaultMacSavingPath]];
    
    // DW: Mac do not use ".xxx" files, remove the first "."
    if ([currentFileName hasPrefix:@"."]) {
        currentFileName = [currentFileName stringByReplacingCharactersInRange:NSRangeFromString(@"0 1") withString:@""];
    }
    
    NSURL *storeURL = [NSURL URLWithString:
                       [NSString stringWithFormat:@"%@/%@.%@",
                        [defaultURL absoluteString],
                        currentFileName,
                        [[self pathExtension] lowercaseString]]];
    // DW: it is really overwhelming that the last "/" of a folder here exists in iOS, but not in Mac
#endif
    DLog(@"NSURL URLWithRemoteChangedToLocal %@", storeURL.path);
    return storeURL;
}

// DW: a good convert from remot URL to local one
// or good convert from local to new local
- (NSURL *)URLWithoutNameConflict {
    NSString *originalFileName = [[self URLByDeletingPathExtension].lastPathComponent stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *currentFileName = originalFileName;
    NSInteger currentFileNamePostfix = 2;
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
    NSURL *storeURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@.%@",
                                            [NSURL iOSDocumentsDirectoryURL].absoluteString,
                                            currentFileName,
                                            [self pathExtension]]];
    while ([[NSFileManager defaultManager] fileExistsAtPath:storeURL.path]) {
        currentFileName = [NSString stringWithFormat:@"%@%%20%i", originalFileName, currentFileNamePostfix++];
        storeURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@.%@", currentFileName, [self pathExtension]]
                          relativeToURL:[self URLByDeletingLastPathComponent]];
    }
#elif TARGET_OS_MAC
    NSURL *defaultURL = [self URLByDeletingLastPathComponent]; // DW: this causes a URL ends with "/"Ω
    NSURL *storeURL = [NSURL URLWithString:
                       [NSString stringWithFormat:@"%@%@.%@",
                        [defaultURL absoluteString],
                        currentFileName,
                        [[self pathExtension] lowercaseString]]];
    while ([[NSFileManager defaultManager] fileExistsAtPath:storeURL.path]) {
        currentFileName = [NSString stringWithFormat:@"%@%%20%i", originalFileName, currentFileNamePostfix++];
        storeURL = [NSURL URLWithString:
                    [NSString stringWithFormat:@"%@%@.%@",
                     [defaultURL absoluteString],
                     currentFileName,
                     [[self pathExtension] lowercaseString]]];
    }
#endif
    DLog(@"NSURL URLWithoutNameConflict %@", storeURL.path);
    return storeURL;
}

- (NSURL *)URLByMovingToParentFolder {
    NSURL *newURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@",
                                            [[self URLByDeletingLastPathComponent] URLByDeletingLastPathComponent].path,
                                            self.lastPathComponent]];
    return newURL;
}

@end
