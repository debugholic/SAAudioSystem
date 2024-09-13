//
//  AudioPlayer.swift
//  Sample
//
//  Created by 김영훈 on 8/30/24.
//  Copyright © 2024 Sidekick-Academy. All rights reserved.
//

import Foundation
import Combine

protocol AudioPlayable {
    var url: String { get }
}

class AudioPlayer: NSObject {
    enum State {
        case initialized
        case ready
        case transitioning
        case playing
        case paused
        case stopped
    }
    
    private lazy var player: AudioQueuePlayer = {
        let player = AudioQueuePlayer()
        player.delegate = self
        return player
    }()
    
    @Published var state: State = .initialized
    
    var playlist: [any AudioPlayable]? {
        didSet {
            if let track = playlist?.first {
                var error: NSError?
                player.insertTrack(track.url, withError: &error)
            }
        } 
    }
    
    func play(completion: ((Error?)->())? = nil) {
        var error: NSError?
        player.playWithError(&error)
        completion?(error)
    }
    
    func pause(completion: ((Error?)->())? = nil) {
        var error: NSError?
        player.pauseWithError(&error)
        completion?(error)
    }
}

extension AudioPlayer: AudioQueuePlayerDelegate {
    func audioPlayer(_ audioPlayer: AudioQueuePlayer, didTrackPlayingForDuration duration: Float64) {
        
    }
    
    func audioPlayer(_ audioPlayer: AudioQueuePlayer, didChange state: AudioQueuePlayerState) {
        switch state {
        case .initialized: self.state = .initialized
        case .ready: self.state = .ready
        case .transitioning: self.state = .transitioning
        case .playing: self.state = .playing
        case .paused: self.state = .paused
        case .stopped: self.state = .stopped
        @unknown default: break
        }
    }
    
    func audioPlayer(_ audioPlayer: AudioQueuePlayer, didTrackReadingProgress progress: Float64) {
        
    }
}
