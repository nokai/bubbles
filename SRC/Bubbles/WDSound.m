//
//  WDSound.m
//  Bubbles
//
//  Created by 王 得希 on 12-2-28.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import "WDSound.h"

@implementation WDSound

- (void)prepareEffects {
	NSURL *tapSound = [[NSBundle mainBundle] URLForResource: @"kWDSoundFileReceived" withExtension: @"aif"];
	_soundFileURLRef = (CFURLRef)[tapSound retain];
	AudioServicesCreateSystemSoundID(_soundFileURLRef, &o);
    [_soundObjects setValue:[NSNumber numberWithLong:o] forKey:kWDSoundFileReceived];
}

- (id)init {
    if (self = [super init]) {
        _soundObjects = [[NSMutableDictionary dictionary] retain];
    }
    return self;
}

#pragma mark - Public Methods

- (void)playSoundForKey:(NSString *)key {
    AudioServicesPlaySystemSound(o);
}

@end
