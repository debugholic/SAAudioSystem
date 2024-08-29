//
//  AudioMetadata.h
//  AudioSystem
//
//  Created by DebugHolic on 08/03/2019.
//  Copyright © 2019 Sidekick-Academy. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString * _Nullable const AudioMetadataTitleKey;
FOUNDATION_EXPORT NSString * _Nullable const AudioMetadataAlbumKey;
FOUNDATION_EXPORT NSString * _Nullable const AudioMetadataArtistKey;
FOUNDATION_EXPORT NSString * _Nullable const AudioMetadataCreatorKey;
FOUNDATION_EXPORT NSString * _Nullable const AudioMetadataDateKey;
FOUNDATION_EXPORT NSString * _Nullable const AudioMetadataSamplerateKey;
FOUNDATION_EXPORT NSString * _Nullable const AudioMetadataBitdepthKey;
FOUNDATION_EXPORT NSString * _Nullable const AudioMetadataChannelsKey;
FOUNDATION_EXPORT NSString * _Nullable const AudioMetadataDurationKey;

@interface AudioMetadata : NSObject

@property (strong, nonatomic, readonly, nullable) NSString *title;
@property (strong, nonatomic, readonly, nullable) NSString *album;
@property (strong, nonatomic, readonly, nullable) NSString *artist;
@property (strong, nonatomic, readonly, nullable) NSString *creator;
@property (strong, nonatomic, readonly, nullable) NSString *date;
@property (assign, nonatomic, readonly) NSUInteger samplerate;
@property (assign, nonatomic, readonly) NSUInteger bitdepth;
@property (assign, nonatomic, readonly) NSUInteger channels;
@property (assign, nonatomic, readonly) NSUInteger duration;

+ (AudioMetadata *_Nonnull)metadataWithDictionary:(NSDictionary *_Nullable)dictionary;
- (instancetype _Nullable)initWithDictionary:(NSDictionary *_Nullable)dictionary;

@end
