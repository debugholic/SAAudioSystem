//
//  AudioEqualizerValue.h
//  Sample
//
//  Created by 김영훈 on 11/18/24.
//  Copyright © 2024 Sidekick-Academy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AudioEqualizerValue: NSObject

@property(class, assign) NSInteger maxGain;
@property(class, assign) NSInteger minGain;

@property(class, readonly, strong, nonnull) NSArray <AudioEqualizerValue *> *defaultBands10;
@property(class, readonly, strong, nonnull) NSArray <AudioEqualizerValue *> *defaultBands20;

@property (assign, nonatomic) double band;
@property (assign, nonatomic) NSInteger gain;
@property (assign, nonatomic) double q;

+ (instancetype _Nonnull)valueWithBand:(double)band;

- (instancetype _Nonnull)initWithBand:(double)band;
- (instancetype _Nonnull)initWithBand:(double)band q:(double)q;
- (instancetype _Nonnull)initWithBand:(double)band gain:(NSInteger)gain;
- (instancetype _Nonnull)initWithBand:(double)band gain:(NSInteger)gain q:(double)q;

@end
