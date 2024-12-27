//
//  Untitled.h
//  Sample
//
//  Created by debugholic on 11/18/24.
//  Copyright © 2024 Sidekick-Academy. All rights reserved.
//

#import "AudioEqualizer.h"

static NSInteger MAX_GAIN = 20;
static NSInteger MIN_GAIN = -20;

@implementation AudioEqualizerValue

+ (NSArray <AudioEqualizerValue *> *)defaultBands10 {
    return @[ [AudioEqualizerValue valueWithBand:31.25], [AudioEqualizerValue valueWithBand:62.5], [AudioEqualizerValue valueWithBand:125.0], [AudioEqualizerValue valueWithBand:250.0], [AudioEqualizerValue valueWithBand:500.0], [AudioEqualizerValue valueWithBand:1000.0], [AudioEqualizerValue valueWithBand:2000.0], [AudioEqualizerValue valueWithBand:4000.0], [AudioEqualizerValue valueWithBand:8000.0], [AudioEqualizerValue valueWithBand:16000.0] ];
}

+ (NSArray <AudioEqualizerValue *> *)defaultBands20 {
    return @[ [AudioEqualizerValue valueWithBand:30], [AudioEqualizerValue valueWithBand:45.0], [AudioEqualizerValue valueWithBand:60.0], [AudioEqualizerValue valueWithBand:90.0], [AudioEqualizerValue valueWithBand:120.0], [AudioEqualizerValue valueWithBand:180.0], [AudioEqualizerValue valueWithBand:250.0], [AudioEqualizerValue valueWithBand:500.0], [AudioEqualizerValue valueWithBand:750.0], [AudioEqualizerValue valueWithBand:1000.0], [AudioEqualizerValue valueWithBand:1500.0], [AudioEqualizerValue valueWithBand:2000.0], [AudioEqualizerValue valueWithBand:3000.0], [AudioEqualizerValue valueWithBand:4000.0], [AudioEqualizerValue valueWithBand:6000.0], [AudioEqualizerValue valueWithBand:8000.0], [AudioEqualizerValue valueWithBand:10000.0], [AudioEqualizerValue valueWithBand:12000.0], [AudioEqualizerValue valueWithBand:14000.0], [AudioEqualizerValue valueWithBand:16000.0] ];
}

+ (void)setMaxGain:(NSInteger)maxGain {
    MAX_GAIN = maxGain;
    if (MAX_GAIN < MIN_GAIN) {
        MAX_GAIN = MIN_GAIN + 1;
    }
}

+ (void)setMinGain:(NSInteger)minGain {
    MIN_GAIN = minGain;
    if (MIN_GAIN > MAX_GAIN) {
        MIN_GAIN = MAX_GAIN - 1;
    }
}

+ (NSInteger)maxGain {
    return MAX_GAIN;
}

+ (NSInteger)minGain {
    return MIN_GAIN;
}

+ (instancetype)valueWithBand:(double)band {
    return [[AudioEqualizerValue alloc] initWithBand:band];
}

- (instancetype)initWithBand:(double)band {
    return [self initWithBand:band gain:0 q:2.0];
}

- (instancetype)initWithBand:(double)band q:(double)q {
    return [self initWithBand:band gain:0 q:q];
}

- (instancetype)initWithBand:(double)band gain:(NSInteger)gain {
    return [self initWithBand:band gain:gain q:2.0];
}

- (instancetype)initWithBand:(double)band gain:(NSInteger)gain q:(double)q {
    self = [super init];
    if (self) {
        _band = band;
        _gain = gain;
        _q = q ? q : 2.0;
    }
    return self;
}

@end
