//
//  Playlist.swift
//  Sample
//
//  Created by debugholic on 12/4/24.
//

import SwiftUI

struct Playlist {
    enum PlayingMode {
        case single
        case loop
        case random
    }
    
    var nowPlayingTrack: (any AudioPlayable)? {
        switch playingMode {
        case .single, .loop:
            return tracklist[trackIndex]
        case .random:
            if let index = shuffled?[trackIndex] { return tracklist[index] } else { return nil }
        }
    }
    
    var nextTrack: (any AudioPlayable)? {
        switch playingMode {
        case .single:
            return tracklist[trackIndex]
        case .loop, .random:
            var trackIndex = trackIndex + 1
            if trackIndex > tracklist.count - 1 {
                trackIndex = 0
            }
            return nowPlayingTrack
        }
    }
    
    var tracklist = [any AudioPlayable]()
    
    private var shuffled: [Int]?
    private var trackIndex = 0
    private var playingMode: PlayingMode = .single {
        didSet {
            shuffled = playingMode == .random ? (0..<tracklist.count).shuffled() : nil
        }
    }
        
    mutating func addTracks(_ tracks: [Track], at index: Int? = nil) -> Bool {
        if let index, index > tracklist.count {
            return false
        }
        
        if let index, index < tracklist.count {
            tracklist.insert(contentsOf: tracks, at: index)
        } else {
            tracklist.append(contentsOf: tracks)
        }
        return true
    }
    
    mutating func addTrack(_ track: Track, at index: Int? = nil) -> Bool {
        if let index, index > tracklist.count {
            return false
        }
        
        if let index, index < tracklist.count {
            tracklist.insert(track, at: index)
        } else {
            tracklist.append(track)
        }
        return true
    }
    
    mutating func removeTracks(at bounds: Range<Int>) {
        tracklist.removeSubrange(bounds)
        if trackIndex > tracklist.count - 1 {
            trackIndex = tracklist.count - 1
        }
    }
    
    mutating func removeTrack(at index: Int) {
        tracklist.remove(at: index)
        if trackIndex > tracklist.count - 1 {
            trackIndex = tracklist.count - 1
        }
    }
    
    mutating func setPlaylist(_ tracks: [any AudioPlayable]) {
        tracklist.removeAll()
        tracklist.append(contentsOf: tracks)
        trackIndex = 0
    }
    
    mutating func skipNextTrack() -> (any AudioPlayable)? {
        trackIndex += 1
        if trackIndex > tracklist.count - 1 {
            trackIndex = 0
        }
        return nowPlayingTrack
    }
    
    mutating func skipPrevTrack() -> (any AudioPlayable)? {
        trackIndex -= 1
        if trackIndex < 0 {
            trackIndex = tracklist.count - 1
        }
        return nowPlayingTrack
    }
}
