//
//  AudioQueuePlayer.h
//  FFmpegAudioPlayer
//
//  Created by DebugHolic on 08/03/2019.
//  Copyright © 2019 Sidekick-Academy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import "AudioQueuePlayer.h"
#import "AudioMetadata.h"
#import "AudioEqualizer.h"

typedef NS_ENUM(NSUInteger, AudioQueuePlayerState) {
    AudioQueuePlayerStateInitialized,
    AudioQueuePlayerStateReady,
    AudioQueuePlayerStateTransitioning,
    AudioQueuePlayerStatePlaying,
    AudioQueuePlayerStatePaused,
    AudioQueuePlayerStateStopped,
};

@class AudioQueuePlayer;

@protocol AudioQueuePlayerDelegate <NSObject>

- (void)audioPlayer:(AudioQueuePlayer *_Nonnull)audioPlayer didTrackPlayingForDuration:(Float64)duration;
- (void)audioPlayer:(AudioQueuePlayer *_Nonnull)audioPlayer didChangeState:(AudioQueuePlayerState)state;
- (void)audioPlayer:(AudioQueuePlayer *_Nonnull)audioPlayer didTrackReadingProgress:(Float64)progress;

@end

@interface AudioQueuePlayer : NSObject

@property (strong, nonatomic, nullable) id <AudioQueuePlayerDelegate> delegate;
@property (assign, nonatomic, readonly) AudioQueuePlayerState state;
@property (assign, nonatomic, readonly) int64_t timeBase;
@property (assign, nonatomic, readonly) BOOL finished;
@property (strong, nonatomic, nullable) AudioEqualizer *equalizer;

- (void)insertTrack:(NSString *_Nullable)path withError:(NSError *_Nullable *_Nonnull)error;
- (void)playWithError:(NSError *_Nullable *_Nonnull)error;
- (void)stopWithError:(NSError *_Nullable *_Nullable)error;
- (void)pauseWithError:(NSError *_Nullable *_Nonnull)error;
- (void)resumeWithError:(NSError *_Nullable *_Nonnull)error;
- (void)seekToTarget:(int64_t)targetTime withError:(NSError *_Nullable *_Nonnull)error;
- (void)terminateWithError:(NSError *_Nullable *_Nonnull)error;
- (AudioMetadata *_Nonnull)metadata;
- (UIImage *_Nullable)albumArt;

@end
