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

@property (strong, nonatomic, nonnull) NSNumber *band;
@property (assign, nonatomic) NSInteger gain;
@property (strong, nonatomic, readonly, nonnull) NSNumber *q;

+ (instancetype _Nonnull)valueWithBand:(NSNumber * _Nonnull)band;

- (instancetype _Nonnull)initWithBand:(NSNumber * _Nonnull)band;
- (instancetype _Nonnull)initWithBand:(NSNumber * _Nonnull)band q:(NSNumber * _Nonnull)q;
- (instancetype _Nonnull)initWithBand:(NSNumber * _Nonnull)band gain:(NSInteger)gain;
- (instancetype _Nonnull)initWithBand:(NSNumber * _Nonnull)band gain:(NSInteger)gain q:(NSNumber * _Nullable)q;

@end
