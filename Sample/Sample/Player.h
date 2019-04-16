//
//  Player.h
//  Sample
//
//  Created by DebugHolic on 27/03/2019.
//  Copyright © 2019 Sidekick-Academy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Track.h"

@interface Player : NSObject

@property Track *curTrack;
@property NSString *curDuration;
@property Float64 progress;

- (void)insertTrackWithURL:(NSString *)URL withSuccess:(void (^)(BOOL, NSError *))successBlock;
- (void)playTrackWithSuccess:(void (^)(BOOL, NSError *))successBlock;
- (void)stopTrackWithSuccess:(void (^)(BOOL, NSError *))successBlock;
- (void)pauseTrackWithSuccess:(void (^)(BOOL, NSError *))successBlock;
- (void)seekToDuration:(NSUInteger)trackDuration withSuccess:(void (^)(BOOL, NSError *))successBlock;
- (void)terminate;

@end
