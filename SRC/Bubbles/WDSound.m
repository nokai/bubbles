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
    NSURL *tapSound = nil;
    CFURLRef soundFileURLRef;
    SystemSoundID o;
    
    // kWDSoundFileReceived
    tapSound = [[NSBundle mainBundle] URLForResource:kWDSoundFileReceived withExtension: @"aif"];
    soundFileURLRef = (CFURLRef)[tapSound retain];
	AudioServicesCreateSystemSoundID(soundFileURLRef, &o);
    [_soundObjects setValue:[NSNumber numberWithLong:o] forKey:kWDSoundFileReceived];
    
    // kWDSoundFileSent
    tapSound = [[NSBundle mainBundle] URLForResource:kWDSoundFileSent withExtension: @"aif"];
    soundFileURLRef = (CFURLRef)[tapSound retain];
	AudioServicesCreateSystemSoundID(soundFileURLRef, &o);
    [_soundObjects setValue:[NSNumber numberWithLong:o] forKey:kWDSoundFileSent];
}

- (id)init {
    if (self = [super init]) {
        _soundObjects = [[NSMutableDictionary dictionary] retain];
        [self prepareEffects];
    }
    return self;
}

#pragma mark - Public Methods

- (void)playSoundForKey:(NSString *)key {
    AudioServicesPlaySystemSound([[_soundObjects objectForKey:key] longValue]);
}

@end
