//
//  SAAudioMetadata.m
//  SAAudioSystem
//
//  Created by DebugHolic on 08/03/2019.
//  Copyright © 2019 Sidekick-Academy. All rights reserved.
//

#import "SAAudioMetadata.h"

NSString * const SAAudioMetadataTitleKey = @"title";
NSString * const SAAudioMetadataAlbumKey = @"album";
NSString * const SAAudioMetadataArtistKey = @"artist";
NSString * const SAAudioMetadataCreatorKey = @"composer";
NSString * const SAAudioMetadataDateKey = @"TYER";
NSString * const SAAudioMetadataSamplerateKey = @"samplerate";
NSString * const SAAudioMetadataBitdepthKey = @"bitdepth";
NSString * const SAAudioMetadataChannelsKey = @"channels";
NSString * const SAAudioMetadataDurationKey = @"duration";


@implementation SAAudioMetadata

+ (SAAudioMetadata *)metadataWithDictionary:(NSDictionary *)dictionary {
    return [[SAAudioMetadata alloc] initWithDictionary:dictionary];
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        self.title = dictionary[SAAudioMetadataTitleKey];
        self.album = dictionary[SAAudioMetadataAlbumKey];
        self.artist = dictionary[SAAudioMetadataArtistKey];
        self.creator = dictionary[SAAudioMetadataCreatorKey];
        self.date = dictionary[SAAudioMetadataDateKey];
        self.samplerate = dictionary[SAAudioMetadataSamplerateKey];
        self.bitdepth = dictionary[SAAudioMetadataBitdepthKey];
        self.channels = dictionary[SAAudioMetadataChannelsKey];
        self.duration = dictionary[SAAudioMetadataDurationKey];
    }
    return self;
}

- (void)setTitle:(NSString * _Nullable)title {
    _title = title;
}

- (void)setAlbum:(NSString * _Nullable)album {
    _album = album;
}

- (void)setArtist:(NSString * _Nullable)artist {
    _artist = artist;
}

- (void)setCreator:(NSString * _Nullable)creator {
    _creator = creator;
}

- (void)setDate:(NSString * _Nullable)date {
    _date = date;
}

- (void)setSamplerate:(NSNumber * _Nullable)samplerate {
    _samplerate = samplerate.unsignedIntegerValue;
}

- (void)setBitdepth:(NSNumber * _Nullable)bitdepth {
    _bitdepth = bitdepth.unsignedIntegerValue;
}

- (void)setChannels:(NSNumber * _Nullable)channels {
    _channels = channels.unsignedIntegerValue;
}

- (void)setDuration:(NSNumber * _Nullable)duration {
    _duration = duration.unsignedIntegerValue;
}

@end
