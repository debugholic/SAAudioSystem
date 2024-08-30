//
//  Track.h
//  Sample
//
//  Created by DebugHolic on 31/03/2019.
//  Copyright © 2019 Sidekick-Academy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AudioMetadata.h"

@interface Track : NSObject

@property (strong, nonatomic, readonly, nullable) NSString *title;
@property (strong, nonatomic, readonly, nullable) NSString *album;
@property (strong, nonatomic, readonly, nullable) NSString *artist;
@property (assign, nonatomic, readonly) NSUInteger samplerate;
@property (assign, nonatomic, readonly) NSUInteger bitdepth;
@property (assign, nonatomic, readonly) NSUInteger duration;
@property (strong, nonatomic, readonly, nullable) UIImage *albumArt;

+ (Track *)trackWithMetadata:(AudioMetadata *)metadata;
+ (Track *)trackWithMetadata:(AudioMetadata *)metadata albumArt:(UIImage *)image;

@end
