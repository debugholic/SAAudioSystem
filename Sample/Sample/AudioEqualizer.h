//
//  AudioEqualizer.h
//  FFmpegAudioPlayer
//
//  Created by DebugHolic on 18/03/2019.
//  Copyright © 2019 Sidekick-Academy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AudioMetadata.h"

@interface AudioEqualizer : NSObject

+ (NSArray <NSNumber *> *_Nonnull)defaultBands_10;
+ (NSArray <NSNumber *> *_Nonnull)defaultBands_20;

@property (strong, nonatomic, nonnull) NSArray <NSNumber *> *bands;
@property (strong, nonatomic, nonnull) NSArray <NSNumber *> *gains;
@property (strong, nonatomic, nonnull) NSArray <NSNumber *> *qFactors;
@property (strong, nonatomic, nonnull) NSNumber *preamp;
@property (strong, nonatomic, readonly, nullable) AudioMetadata *metadata;


- (instancetype _Nullable)initWithBands:(NSArray <NSNumber *> * _Nonnull)bands;
- (int)filter:(void *_Nullable)data length:(size_t)length;

@end
