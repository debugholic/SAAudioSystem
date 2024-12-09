//
//  PlayerViewModel.swift
//  Sample
//
//  Created by 김영훈 on 9/9/24.
//  Copyright © 2024 Sidekick-Academy. All rights reserved.
//

import SwiftUI
import Combine

class PlayerViewModel: ObservableObject {
    private var player = AudioPlayer()
    private var playlist = Playlist()

    @Published var state: AudioPlayer.State = .initialized
    @Published var error: Error?
    
    @Published var nowPlaying: Track?
    @Published var duration: Double = 0
        
    var isEditSeeking: Bool = false
    var playingIndex: Int = 0
    var subscriptions = Set<AnyCancellable>()
    
    private var equalizer: AudioEqualizer = AudioEqualizer(values: AudioEqualizerValue.defaultBands10)
    
    var tracks: [Track] {
        return playlist.tracklist as? [Track] ?? []
    }
    
    var isEqualizerEnabled: Bool {
        set {
            player.equalizer?.on = newValue
            UserDefaults.standard.set(newValue, forKey: "isEqualizerEnabled")
            
        } get {
            UserDefaults.standard.bool(forKey: "isEqualizerEnabled")
        }
    }
    
    lazy var equalizerValues: [AudioEqualizerValue] = equalizer.values
    
    init() {
        player.duration.sink { duration in
            DispatchQueue.main.async {
                if !self.isEditSeeking {
                    self.duration = duration
                }
            }
        }.store(in: &subscriptions)
 
        player.state.sink { state in
            DispatchQueue.main.async {
                self.state = state
            }
        }.store(in: &subscriptions)
        
        player.nowPlaying.sink { track in
            DispatchQueue.main.async {
                self.nowPlaying = track as? Track
            }
        }.store(in: &subscriptions)

        player.error.sink { error in
            DispatchQueue.main.async {
                self.error = error
            }
        }.store(in: &subscriptions)
        player.equalizer = equalizer
        player.equalizer?.on = isEqualizerEnabled
    }
            
    func setPlaylist(_ tracks: [Track]) {
        playlist.setPlaylist(tracks)
        if let track = playlist.currentTrack as? Track {
            insertTrack(track)
        }
    }
    
    func insertTrack(_ track: Track) {
        player.insertTrack(track)
    }
    
    func play() {
        switch state {
        case .stopped:
            if let track = playlist.currentTrack as? Track {
                insertTrack(track)
                try? player.play()
            }
            break

        case .finished:
            if let track = playlist.nextTrack as? Track {
                insertTrack(track)
                try? player.play()
            }
            break
            
        default:
            try? player.play()
            break
        }
    }
    
    func resume() {
        player.resume()
    }
    
    func pause() {
        player.pause()
    }
    
    func stop() {
        player.stop()
    }
    
    func skipNext() {
        let state = self.state
        player.stop()
        
        if let track = playlist.skipNextTrack() as? Track {
            insertTrack(track)
            if state == .playing {
                play()
            }
        }
    }
    
    func skipPrev() {
        let state = self.state
        player.stop()
        
        if let track = playlist.skipPrevTrack() as? Track {
            insertTrack(track)
            if state == .playing {
                play()
            }
        }
    }
    
    func seek(to target: TimeInterval) {
        player.seek(to: target)
    }
    
    func tune() {
        equalizer.tune()
    }
}

extension Double {
    func dateFormatted() -> String {
        let duration = self
        let hours = duration / 60 / 60
        let minutes = duration / 60
        let seconds = duration.truncatingRemainder(dividingBy: 60)
        return String(format: "%02d:%02d:%02d", Int(hours), Int(minutes), Int(seconds))
    }
}
