//
//  Track.swift
//  Sample
//
//  Created by 김영훈 on 12/6/24.
//  Copyright © 2024 Sidekick-Academy. All rights reserved.
//

import Foundation

struct Track: AudioPlayable {
    let mediaInfo: MediaInfo?
    let albumArt: UIImage?
    let path: String
    
    init(_ path: String) {
        self.path = path
        
        let metadata = MetadataExtractor.metadata(withPath: path)
        self.mediaInfo = MediaInfo(metadata: metadata)
        
        self.albumArt = AlbumArtExtractor.albumArt(withPath: path)
    }
}

struct MediaInfo {
    let title: String?
    let album: String?
    let artist: String?
    let creator: String?
    let date: String?
    let samplerate: UInt
    let bitdepth: UInt
    let channels: UInt
    let duration: UInt

    init(title: String? = nil, album: String? = nil, artist: String? = nil, creator: String? = nil, date: String? = nil, samplerate: UInt? = nil, bitdepth: UInt? = nil, channels: UInt? = nil, duration: UInt?) {
        self.title = title
        self.album = album
        self.artist = artist
        self.creator = creator
        self.date = date
        self.samplerate = samplerate ?? 0
        self.bitdepth = bitdepth ?? 0
        self.channels = channels ?? 0
        self.duration = duration ?? 0
    }
    
    init(metadata: AudioMetadata?) {
        let title = metadata?.title
        let album = metadata?.album
        let artist = metadata?.artist
        let creator = metadata?.creator
        let date = metadata?.date
        let samplerate = metadata?.samplerate
        let bitdepth = metadata?.bitdepth
        let channels = metadata?.channels
        let duration = metadata?.duration
        
        self.init(title: title, album: album, artist: artist, creator: creator, date: date, samplerate: samplerate, bitdepth: bitdepth, channels: channels, duration: duration)
    }
}
//
//
//
//
//- (instancetype)initWithFile:(NSString *)filePath {
//    self = [self init];
//    if (self) {
//        BOOL isDirectory = NO;
//        [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory];
//        NSString *fileName = filePath.lastPathComponent;
//        if (isDirectory) {
//            self.itemTitle = fileName;
//            self.storageResourceURLString = filePath;
//            self.objectClass = UPnPObjectClass.STORAGE_FOLDER;
//            self.playable = YES;
//        } else {
//            if (DoesFileHasSupportedExtension(fileName)) {
//                self.itemTitle = fileName;
//                self.storageResourceURLString = filePath;
//                self.objectClass = UPnPObjectClass.MUSIC_TRACK;
//                self.editable = YES;
//                UPPMediaItemResource *resource = [[UPPMediaItemResource alloc] init];
//                resource.protocolInfo = [AKCProtocolInfoHelper protocolInfoFromExtension:nil];
//                self.resources = @[resource];
//                
//                dispatch_queue_t parseQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
//                dispatch_async(parseQueue, ^{
//                    // PARSE IT AND INSERT IT TO DB
//                    NSDictionary *metadata = [IRVMetadataExtractor extractMetadataWithPath:filePath];
//                    NSString *album = metadata[@"album"];
//                    if (!album) {
//                        album = NSLocalizedString(AKCLocalizedStringItemUnknownAlbumKey, nil);
//                    }
//                    self.albumTitle = album;
//                    
//                    NSString *artist = metadata[@"artist"];
//                    if (!artist) {
//                        artist = NSLocalizedString(AKCLocalizedStringItemUnknownArtistKey, nil);
//                    }
//                    self.artist = artist;
//                    
//                    NSString *genre = metadata[@"genre"];
//                    if (!genre) {
//                        genre = NSLocalizedString(AKCLocalizedStringItemUnknownGenreKey, nil);
//                    }
//                    self.genre = genre;
//                    
//                    self.creator = metadata[@"composer"];
//                    self.date = metadata[@"TYER"];
//                    self.trackNumber = metadata[@"track"];
//                    self.playable = YES;
//                });
//            }
//        }
//    }
//    return self;
//}
