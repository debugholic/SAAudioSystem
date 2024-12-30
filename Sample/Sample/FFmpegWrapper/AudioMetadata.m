//
//  AudioMetadata.m
//  FFmpegAudioPlayer
//
//  Created by DebugHolic on 08/03/2019.
//  Copyright © 2019 Sidekick-Academy. All rights reserved.
//

#import "AudioMetadata.h"

NSString * const AudioMetadataTitleKey = @"title";
NSString * const AudioMetadataAlbumKey = @"album";
NSString * const AudioMetadataArtistKey = @"artist";
NSString * const AudioMetadataCreatorKey = @"composer";
NSString * const AudioMetadataDateKey = @"TYER";
NSString * const AudioMetadataSamplerateKey = @"samplerate";
NSString * const AudioMetadataBitdepthKey = @"bitdepth";
NSString * const AudioMetadataChannelsKey = @"channels";
NSString * const AudioMetadataDurationKey = @"duration";
NSString * const AudioMetadataSampleformatKey = @"sampleformat";

@implementation AudioMetadata

+ (AudioMetadata *)metadataWithDictionary:(NSDictionary *)dictionary {
    return [[AudioMetadata alloc] initWithDictionary:dictionary];
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        self.title = dictionary[AudioMetadataTitleKey];
        self.album = dictionary[AudioMetadataAlbumKey];
        self.artist = dictionary[AudioMetadataArtistKey];
        self.creator = dictionary[AudioMetadataCreatorKey];
        self.date = dictionary[AudioMetadataDateKey];
        self.samplerate = dictionary[AudioMetadataSamplerateKey];
        self.bitdepth = dictionary[AudioMetadataBitdepthKey];
        self.channels = dictionary[AudioMetadataChannelsKey];
        self.duration = dictionary[AudioMetadataDurationKey];
        self.sampleformat = dictionary[AudioMetadataSampleformatKey];
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

- (void)setSampleformat:(NSString * _Nonnull)sampleformat {
    _sampleformat = sampleformat;
}

@end
