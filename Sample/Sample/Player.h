//
//  Player.h
//  FFmpegAudioPlayer
//
//  Created by DebugHolic on 27/03/2019.
//  Copyright © 2019 Sidekick-Academy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AudioQueuePlayer.h"
#import "Track.h"

@class Player;

@protocol PlayerDelegate <NSObject>

- (void)player:(Player *)player didChangeState:(AudioQueuePlayerState)state;
- (void)player:(Player *)player didTrackPlayingForDuration:(Float64)duration;

@end

@interface Player : NSObject

@property (strong, nonatomic) Track *curTrack;
@property (assign, nonatomic) NSUInteger curDuration;
@property (assign, nonatomic) Float64 progress;
@property (weak, nonatomic) id <PlayerDelegate> delegate;

- (void)insertTrackWithURL:(NSString *)URL withSuccess:(void (^)(BOOL, NSError *))successBlock;
- (void)playTrackWithSuccess:(void (^)(BOOL, NSError *))successBlock;
- (void)stopTrackWithSuccess:(void (^)(BOOL, NSError *))successBlock;
- (void)pauseTrackWithSuccess:(void (^)(BOOL, NSError *))successBlock;
- (void)seekToDuration:(NSUInteger)trackDuration withSuccess:(void (^)(BOOL, NSError *))successBlock;
- (void)terminate;

@end
