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

class AudioPlayer {
    private var player = AudioQueuePlayer()
    
    var playlist: [any AudioPlayable]? {
        didSet {
            if let track = playlist?.first {
                var error: NSError?
                player.insertTrack(track.url, withError: &error)
                print(error?.localizedDescription)
            }
        }
    }
    
    func play() {
        var error: NSError?
        player.playWithError(&error)
        print(error?.localizedDescription)
    }
}
