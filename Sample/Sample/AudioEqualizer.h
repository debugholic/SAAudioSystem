//
//  AudioEqualizer.h
//  FFmpegAudioPlayer
//
//  Created by DebugHolic on 18/03/2019.
//  Copyright © 2019 Sidekick-Academy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AudioMetadata.h"

typedef enum : NSUInteger {
    AudioEqualizerFlagNone,
    AudioEqualizerFlagOn,
    AudioEqualizerFlagOff,
} AudioEqualizerFlag;

@interface AudioEqualizer : NSObject

@property (strong, nonatomic, nonnull) NSArray <NSNumber *> *bands;
@property (strong, nonatomic, nonnull) NSArray <NSNumber *> *gains;
@property (strong, nonatomic, nonnull) NSArray <NSNumber *> *qFactors;
@property (strong, nonatomic, nonnull) NSNumber *preamp;
@property (strong, nonatomic, readonly, nullable) AudioMetadata *metadata;

- (instancetype _Nonnull)initWithDefautBands_10;
- (instancetype _Nonnull )initWithDefautBands_20;
- (int)adjust:(void *_Nullable)data length:(size_t)length flag:(AudioEqualizerFlag)flag;

@end
