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
    var path: String { get }
    var mediaInfo: MediaInfo? { get }
    var albumArt: UIImage? { get }
}

final class AudioPlayer: NSObject {
    enum State {
        case initialized
        case ready
        case transitioning
        case playing
        case paused
        case stopped
        case finished
    }
    
    private lazy var player: AudioQueuePlayer = {
        let player = AudioQueuePlayer()
        player.delegate = self
        return player
    }()
    
    var equalizer: AudioEqualizer? {
        set { player.equalizer = newValue }
        get { player.equalizer  }
    }
    var state = PassthroughSubject<State, Never>()
    var duration = PassthroughSubject<Double, Never>()
    var progress = PassthroughSubject<Double, Never>()
    var nowPlaying = PassthroughSubject<(any AudioPlayable), Never>()
    var error = PassthroughSubject<Error?, Never>()
    
    func insertTrack(_ track: any AudioPlayable) {
        var error: NSError?
        player.insertTrack(track.path, withError: &error)
        nowPlaying.send(track)
        self.error.send(error)
    }
    
    func play() throws {
        var error: NSError?
        player.playWithError(&error)
        self.error.send(error)
    }
    
    func pause() {
        var error: NSError?
        player.pauseWithError(&error)
        self.error.send(error)
    }

    func resume() {
        var error: NSError?
        player.resumeWithError(&error)
        self.error.send(error)
    }
    
    func stop() {
        var error: NSError?
        player.stopWithError(&error)
        self.error.send(error)
    }
    
    func seek(to target: TimeInterval) {
        var error: NSError?
        player.seek(toTarget: Int64(ceil(target)), withError: &error)
        self.error.send(error)
    }
}

extension AudioPlayer: AudioQueuePlayerDelegate {
    func audioPlayer(_ audioPlayer: AudioQueuePlayer, didTrackPlayingForDuration duration: Float64) {
        self.duration.send(duration)
    }
    
    func audioPlayer(_ audioPlayer: AudioQueuePlayer, didChange state: AudioQueuePlayerState) {
        switch state {
        case .initialized: self.state.send(.initialized)
        case .ready: self.state.send(.ready)
        case .transitioning: self.state.send(.transitioning)
        case .playing: self.state.send(.playing)
        case .paused: self.state.send(.paused)
        case .stopped: self.state.send(.stopped)
        case .finished: self.state.send(.finished)
        @unknown default: break
        }        
    }
    
    func audioPlayer(_ audioPlayer: AudioQueuePlayer, didTrackReadingProgress progress: Float64) {
        self.progress.send(progress)
    }
}
