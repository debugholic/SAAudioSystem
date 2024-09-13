//
//  PlayerViewModel.swift
//  Sample
//
//  Created by 김영훈 on 9/9/24.
//  Copyright © 2024 Sidekick-Academy. All rights reserved.
//

import SwiftUI
import Combine

class PlayerViewModel {
    private var player = AudioPlayer()
    @Published var state: AudioPlayer.State = .initialized
    @Published var error: Error?
    
    func setPlaylist(_ playlist:[any AudioPlayable]) {
        player.playlist = playlist
    }
    
    func playAudio() {
        player.play { self.error = $0 }
        state = .playing
    }
    
    func pauseAudio() {
        player.pause { self.error = $0 }
        state = .paused
    }

}
