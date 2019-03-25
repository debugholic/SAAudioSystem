//
//  SAAudioMetadata.h
//  SAAudioSystem
//
//  Created by DebugHolic on 08/03/2019.
//  Copyright © 2019 Sidekick-Academy. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString * const SAAudioMetadataTitleKey;
FOUNDATION_EXPORT NSString * const SAAudioMetadataAlbumKey;
FOUNDATION_EXPORT NSString * const SAAudioMetadataArtistKey;
FOUNDATION_EXPORT NSString * const SAAudioMetadataCreatorKey;
FOUNDATION_EXPORT NSString * const SAAudioMetadataDateKey;
FOUNDATION_EXPORT NSString * const SAAudioMetadataSamplerateKey;
FOUNDATION_EXPORT NSString * const SAAudioMetadataBitdepthKey;
FOUNDATION_EXPORT NSString * const SAAudioMetadataChannelsKey;
FOUNDATION_EXPORT NSString * const SAAudioMetadataDurationKey;

@interface SAAudioMetadata : NSObject

@property (strong, nonatomic, readonly, nullable) NSString *title;
@property (strong, nonatomic, readonly, nullable) NSString *album;
@property (strong, nonatomic, readonly, nullable) NSString *artist;
@property (strong, nonatomic, readonly, nullable) NSString *creator;
@property (strong, nonatomic, readonly, nullable) NSString *date;
@property (assign, nonatomic, readonly) NSUInteger samplerate;
@property (assign, nonatomic, readonly) NSUInteger bitdepth;
@property (assign, nonatomic, readonly) NSUInteger channels;
@property (assign, nonatomic, readonly) NSUInteger duration;

+ (SAAudioMetadata *)metadataWithDictionary:(NSDictionary *)dictionary;
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end
