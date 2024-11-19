//
//  PlayerViewModel.swift
//  Sample
//
//  Created by 김영훈 on 9/9/24.
//  Copyright © 2024 Sidekick-Academy. All rights reserved.
//

import SwiftUI
import Combine

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

class PlayerViewModel: ObservableObject {
    private var player = AudioPlayer()
    
    @Published var state: AudioPlayer.State = .initialized
    @Published var error: Error?
    @Published var mediaInfo: MediaInfo?
    @Published var albumArt: UIImage?
    @Published var duration: Double = 0
        
    var isEditSeeking: Bool = false
    var playlist: [any AudioPlayable]? {
        didSet {
            insert()
        }
    }
    var playingIndex: Int = 0
    var subscriptions = Set<AnyCancellable>()
    @Published var equalizer: AudioEqualizer = AudioEqualizer(values: AudioEqualizerValue.defaultBands10)
    
    var isEqualizerEnabled: Bool {
        set {
            player.equalizer = newValue ? equalizer : nil
            UserDefaults.standard.set(newValue, forKey: "isEqualizerEnabled")
            
        } get {
            UserDefaults.standard.bool(forKey: "isEqualizerEnabled")
        }
    }
    
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
        
        player.metadata.sink { metadata in
            DispatchQueue.main.async {
                self.mediaInfo = MediaInfo(metadata: metadata)
            }
        }.store(in: &subscriptions)

        player.albumArt.sink { albumArt in
            DispatchQueue.main.async {
                self.albumArt = albumArt
            }
        }.store(in: &subscriptions)
        
        player.error.sink { error in
            DispatchQueue.main.async {
                self.error = error
            }
        }.store(in: &subscriptions)
        player.equalizer = equalizer
    }
    
    private func insert() {
        if playingIndex < (playlist?.count ?? 0),
           let track = playlist?[playingIndex] {
            player.insertTrack(track)
        }
    }
        
    func play() {
        try? player.play()
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
    
    func next() {
        let state = self.state
        if playingIndex < (playlist?.count ?? 0) - 1 {
            playingIndex += 1
            player.stop()
        }
        insert()
        if state == .playing {
            play()
        }
    }
    
    func prev() {
        let state = self.state
        player.stop()
        if duration < 3  && playingIndex >= 1 {
            playingIndex -= 1
        }
        insert()
        if state == .playing {
            play()
        }
    }
    
    func seek(to target: TimeInterval) {
        player.seek(to: target)
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
