//
//  Player.m
//  FFmpegAudioPlayer
//
//  Created by DebugHolic on 27/03/2019.
//  Copyright © 2019 Sidekick-Academy. All rights reserved.
//

#import "Player.h"
#import <AVFoundation/AVFoundation.h>
#import "AudioQueuePlayer.h"

@interface Player() <AudioQueuePlayerDelegate>

@property (strong, nonatomic) AudioQueuePlayer *audioPlayer;
@property (assign, nonatomic) NSUInteger volume;
@property (assign, nonatomic) AudioQueuePlayerState state;

@end

@implementation Player

const NSUInteger MaxVolume = 100;

- (instancetype)init {
    self = [super init];
    if (self) {
        self.curDuration = 0;
        self.state = AudioQueuePlayerStateInitialized;
        self.audioPlayer = [[AudioQueuePlayer alloc] init];
        self.audioPlayer.delegate = self;
        self.volume = (NSUInteger)(MaxVolume * [[AVAudioSession sharedInstance] outputVolume]);
    }
    return self;
}

- (void)insertTrackWithURL:(NSString *)URL withSuccess:(void (^)(BOOL, NSError *))successBlock {
    dispatch_queue_t insertQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_async(insertQueue, ^{
        NSError *error = nil;
        if ((self.state == AudioQueuePlayerStateStopped
            || self.state == AudioQueuePlayerStateInitialized) && URL) {
            [self.audioPlayer insertTrack:URL withError:&error];
            if (successBlock && !error) {
                self.curTrack = [Track trackWithMetadata:self.audioPlayer.metadata albumArt:self.audioPlayer.albumArt];
                self.state = AudioQueuePlayerStateReady;
                successBlock(YES, error);
                return;
            }
        }
        if (successBlock) {
            successBlock(NO, error);
        }
    });
}

- (void)playTrackWithSuccess:(void (^)(BOOL, NSError *))successBlock {
    dispatch_queue_t playQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_async(playQueue, ^{
        NSError *error = nil;
        if (self.state == AudioQueuePlayerStatePaused) {
            [self.audioPlayer resumeWithError:&error];
            if (successBlock && !error) {
                successBlock(YES, error);
                return;
            }
        } else {
            if (self.state == AudioQueuePlayerStateReady) {
                [self.audioPlayer playWithError:&error];
                if (successBlock && !error) {
                    successBlock(YES, error);
                    return;
                }
            }
        }
        if (successBlock) {
            successBlock(NO, error);
        }
    });
}

- (void)stopTrackWithSuccess:(void (^)(BOOL, NSError *))successBlock {
    dispatch_queue_t stopQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_async(stopQueue, ^{
        NSError *error = nil;
        if (self.state == AudioQueuePlayerStateStopped || self.state == AudioQueuePlayerStateInitialized) {
            if (successBlock) {
                successBlock(YES, error);
            }
            return;
        }
        
        [self.audioPlayer stopWithError:&error];
        if (successBlock && !error) {
            successBlock(YES, error);
            return;
        }
        self.curDuration = 0;
        if (successBlock) {
            successBlock(YES, error);
        }
    });
}

- (void)pauseTrackWithSuccess:(void (^)(BOOL, NSError *))successBlock {
    NSError *error = nil;
    [self.audioPlayer pauseWithError:&error];
    if (successBlock && !error) {
        successBlock(YES, error);
        return;
    }
    if (successBlock) {
        successBlock(NO, error);
    }
}

- (void)seekToDuration:(NSUInteger)trackDuration withSuccess:(void (^)(BOOL, NSError *))successBlock {
    dispatch_queue_t seekQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_async(seekQueue, ^{
        NSError *error = nil;
        if (self.state == AudioQueuePlayerStatePaused
            || self.state == AudioQueuePlayerStatePlaying) {
            if (trackDuration <= self.curTrack.duration) {
                self.curDuration = trackDuration;
                [self.audioPlayer seekToTarget:(int64_t)trackDuration withError:&error];
                if (successBlock && !error) {
                    successBlock(YES, error);
                    return;
                }
            }
        }
        if (successBlock) {
            successBlock(NO, nil);
        }
    });
}

- (void)terminate {
    [self.audioPlayer terminateWithError:nil];
}

- (void)audioPlayer:(AudioQueuePlayer *)audioPlayer didChangeState:(AudioQueuePlayerState)state {
    self.state = state;
    [self.delegate player:self didChangeState:state];
}

- (void)audioPlayer:(AudioQueuePlayer *)audioPlayer didTrackReadingProgress:(Float64)progress {
    _progress = progress;
}

- (void)audioPlayer:(AudioQueuePlayer *)audioPlayer didTrackPlayingForDuration:(Float64)duration {
    if (self.state == AudioQueuePlayerStateTransitioning) {
       return;
    }

    if (duration - floor(duration) > 0.5) {
        self.curDuration = (NSUInteger)ceil(duration);
    } else {
        self.curDuration = (NSUInteger)floor(duration);
    }
    [self.delegate player:self didTrackPlayingForDuration:duration];
}

@end
