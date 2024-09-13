//
//  ContentView.swift
//  MyAudioPlayer
//
//  Created by 김영훈 on 8/28/24.
//

import SwiftUI

struct Track: AudioPlayable {
    let url: String
}

struct Button: View {
    let action: (() -> Void)
    let imageName: String
    var body: some View {
        SwiftUI.Button(action: action, label: {
            Image(imageName).resizable()
                .font(.system(size: 36))
                .foregroundColor(.red)
                .scaledToFit()
                .frame(width: 40, height: 40)
                .clipped()
                .padding(6)
        })
    }
}

struct PlayerView: View {
    var viewModel = PlayerViewModel()
    @State private var isPlaying : Bool = false

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            NavigationBar()
            Divider()
                .background(Color.black)
            GeometryReader { geometry in
                VStack {
                    Image("")
                        .frame(width: min(geometry.size.width, geometry.size.height),
                               height: min(geometry.size.width, geometry.size.height))
                        .background(Color.red)
                    HStack(spacing: 4) {
                        Text("-")
                        Text("/")
                        Text("-")
                    }
                    .padding(EdgeInsets(top: 32, leading: 8, bottom: 16, trailing: 8))
                    Text("Title")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Artist")
                        .font(.title3)
                    HStack(spacing: 36) {
                        Button(action: { }, imageName: "reverse")
                            .frame(width: 50, height: 50)
                        Button(action: {
                            switch viewModel.state {
                            case .initialized:
                                if let path = Bundle.main.path(forResource: "Canon in D", ofType: "mp3") {
                                    viewModel.setPlaylist([Track(url: path)])
                                }
                                viewModel.playAudio()
                                isPlaying = true
                                break
                                
                            case .ready, .paused, .stopped:
                                viewModel.playAudio()
                                isPlaying = true
                                break
                                
                            case .playing:
                                viewModel.pauseAudio()
                                isPlaying = false
                                break
                                
                            default:
                                break
                            }
                        }, imageName: isPlaying ? "pause" : "play")
                        .frame(width: 50, height: 50)
                        Button(action: { }, imageName: "forward")
                            .frame(width: 50, height: 50)
                    }
                    .padding(EdgeInsets(top: 8, leading: 8, bottom: 16, trailing: 8))
                }
            }
            .padding(24)
            Divider()
            BottomBar()
        }
            
            //                NavigationBar()
            //                    .frame()
            //                    .background(Color.red)
            //                Button("버튼") {
            //                    if let path = Bundle.main.path(forResource: "Canon in D", ofType: "mp3") {
            //                        player.playlist = [Track(url: path)]
            //                        player.play()
            //                    }
            //                }
    }
}

struct NavigationBar: View {
    var body: some View {
        HStack {
            Button(action: { }, imageName: "musicfile")
            .padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
            Spacer()
        }
    }
}

struct BottomBar: View {
    var body: some View {
        HStack {
            Button(action: { }, imageName: "equalizer")
                .padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
            Spacer()
            Button(action: { }, imageName: "playlist")
                .padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
        }
    }
}

#Preview {
    PlayerView()
}