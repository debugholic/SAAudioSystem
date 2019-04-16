//
//  Track.m
//  Sample
//
//  Created by DebugHolic on 31/03/2019.
//  Copyright © 2019 Sidekick-Academy. All rights reserved.
//

#import "Track.h"

@implementation Track

+ (Track *)trackWithMetadata:(SAAudioMetadata *)metadata {
    return [self.class trackWithMetadata:metadata albumArt:nil];
}

+ (Track *)trackWithMetadata:(SAAudioMetadata *)metadata albumArt:(UIImage *)image {
    Track *track = [[Track alloc] init];
    if (metadata.title) {
        track.title = [NSString stringWithString:metadata.title];
    }
    if (metadata.artist) {
        track.artist = [NSString stringWithString:metadata.artist];
    }
    if (metadata.album) {
        track.album = [NSString stringWithString:metadata.album];
    }
    track.duration = metadata.duration;
    track.bitdepth = metadata.bitdepth;
    track.samplerate = metadata.samplerate;
    track.albumArt = image;
    return track;
}

- (void)setDuration:(NSUInteger)duration {
    _duration = duration;
}

- (void)setAlbum:(NSString * _Nullable)album {
    _album = album;
}

- (void)setTitle:(NSString * _Nullable)title {
    _title = title;
}

- (void)setArtist:(NSString * _Nullable)artist {
    _artist = artist;
}

- (void)setBitdepth:(NSUInteger)bitdepth {
    _bitdepth = bitdepth;
}

- (void)setSamplerate:(NSUInteger)samplerate {
    _samplerate = samplerate;
}

- (void)setAlbumArt:(UIImage * _Nullable)albumArt {
    _albumArt = albumArt;
}

@end
