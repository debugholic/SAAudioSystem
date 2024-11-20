//
//  AudioEqualizer.h
//  FFmpegAudioPlayer
//
//  Created by DebugHolic on 18/03/2019.
//  Copyright © 2019 Sidekick-Academy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AudioEqualizerValue.h"
#import "AudioMetadata.h"

@interface AudioEqualizer: NSObject

@property (strong, nonatomic, nonnull) NSArray <AudioEqualizerValue *> *values;
@property (assign, nonatomic) float preamp;
@property (strong, nonatomic, nullable) AudioMetadata *metadata;

- (instancetype _Nonnull)initWithValues:(NSArray <AudioEqualizerValue *> * _Nonnull)values;
- (int)filter:(void *_Nullable)data length:(size_t)length;
- (int)changeFilter;

@end
