//
//  SAAudioPlayer.h
//  SAAudioSystem
//
//  Created by DebugHolic on 08/03/2019.
//  Copyright © 2019 Sidekick-Academy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import "SAAudioPlayer.h"

typedef NS_ENUM(NSUInteger, SAAudioPlayerState) {
    SAAudioPlayerStateInitialized,
    SAAudioPlayerStateReady,
    SAAudioPlayerStateTransitioning,
    SAAudioPlayerStatePlaying,
    SAAudioPlayerStatePaused,
    SAAudioPlayerStateStopped,
};

@class SAAudioPlayer;

@protocol SAAudioPlayerDelegate <NSObject>

- (void)audioPlayer:(SAAudioPlayer *)audioPlayer didTrackPlayingAsDuration:(Float64)duration;
- (void)audioPlayer:(SAAudioPlayer *)audioPlayer didChangeState:(SAAudioPlayerState)state;
- (void)audioPlayer:(SAAudioPlayer *)audioPlayer didTrackReadingProgress:(Float64)progress;

@end

@interface SAAudioPlayer : NSObject

@property (strong, nonatomic, nullable) id <SAAudioPlayerDelegate> delegate;
@property (assign, nonatomic, readonly) SAAudioPlayerState state;
@property (assign, nonatomic, readonly) int64_t timeBase;
@property (assign, nonatomic, readonly) BOOL finished;

- (void)insertTrack:(NSString *)path withError:(NSError **)error;
- (void)playWithError:(NSError **)error;
- (void)stopWithError:(NSError **)error;
- (void)pauseWithError:(NSError **)error;
- (void)resumeWithError:(NSError **)error;
- (void)seekToTarget:(int64_t)targetTime withError:(NSError **)error;
- (void)terminateWithError:(NSError **)error;

@end
