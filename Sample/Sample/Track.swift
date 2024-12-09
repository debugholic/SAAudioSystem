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
        self.mediaInfo = MediaInfo(metadata: MetadataExtractor.metadata(withPath: path))
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
