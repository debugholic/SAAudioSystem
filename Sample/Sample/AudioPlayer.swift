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

    var state = PassthroughSubject<State, Never>()
    var duration = PassthroughSubject<Double, Never>()
    var progress = PassthroughSubject<Double, Never>()
    var metadata = PassthroughSubject<AudioMetadata, Never>()
    var albumArt = PassthroughSubject<UIImage?, Never>()
    var error = PassthroughSubject<Error?, Never>()

    func insertTrack(_ track: any AudioPlayable) {
        var error: NSError?
        player.insertTrack(track.url, withError: &error)
        metadata.send(player.metadata())
        albumArt.send(player.albumArt())
        self.error.send(error)
    }
    
    func play() {
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
        print(target, Int64(ceil(target)))
        player.seek(toTarget: Int64(ceil(target)), withError: &error)
        self.error.send(error)
    }
    
//    - (void)seekToTarget:(int64_t)targetTime withError:(NSError *_Nullable *_Nonnull)error;
//    - (void)adjustEQ:(BOOL)adjust;
//    - (void)terminateWithError:(NSError *_Nullable *_Nonnull)error;

}

extension AudioPlayer: AudioQueuePlayerDelegate {
    func audioPlayer(_ audioPlayer: AudioQueuePlayer, didTrackPlayingForDuration duration: Float64) {
//        print(duration)
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
        @unknown default: break
        }
    }
    
    func audioPlayer(_ audioPlayer: AudioQueuePlayer, didTrackReadingProgress progress: Float64) {
        self.progress.send(progress)
    }
}
