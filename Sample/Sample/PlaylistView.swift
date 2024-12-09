//
//  PlaylistView.swift
//  Sample
//
//  Created by debugholic on 12/6/24.
//

import SwiftUI

struct PlaylistView: View {
    @ObservedObject var viewModel: PlayerViewModel
    
    var body: some View {
        List(viewModel.tracks, id: \.path) { track in
            HStack {
                Image(uiImage: track.albumArt ?? UIImage())
                    .resizable()
                    .frame(width: 30, height: 30)
                    .background(Color.gray.opacity(0.7))
                    .cornerRadius(2)
                    .scaledToFill()
                
                Text(track.mediaInfo?.title ?? "")
                    .layoutPriority(1)
                Text("-")
                Text(track.mediaInfo?.artist ?? "")
            }
            .foregroundStyle(track.path == viewModel.nowPlaying?.path ? Color.red : Color.black)
            .lineLimit(1)
            .onTapGesture {
                viewModel.stop()
                viewModel.insertTrack(track)
                viewModel.play()
            }
        }
    }
}

