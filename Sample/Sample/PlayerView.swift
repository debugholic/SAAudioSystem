//
//  ContentView.swift
//  MyAudioPlayer
//
//  Created by debugholic on 8/28/24.
//

import SwiftUI

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
    @ObservedObject var viewModel = {
        let viewModel = PlayerViewModel()
        
        var tracks = [Track]()
        if let path = Bundle.main.path(forResource: "Pavane for Dead Princess", ofType: "mp3") {
            tracks.append(Track(path))
        }
        
        if let path = Bundle.main.path(forResource: "Canon in D", ofType: "mp3") {
            tracks.append(Track(path))
        }
        
        if let path = Bundle.main.path(forResource: "Nocturne in C# minor", ofType: "mp3") {
            tracks.append(Track(path))
        }
        
        if let path = Bundle.main.path(forResource: "Carmen Habanera", ofType: "mp3") {
            tracks.append(Track(path))
        }
        
        if let path = Bundle.main.path(forResource: "Minuet in G", ofType: "mp3") {
            tracks.append(Track(path))
        }
        
        viewModel.setPlaylist(tracks)
        return viewModel
    }()
    
    @State private var isEditing = false

    var body: some View {
        NavigationView {
            VStack(alignment: .center, spacing: 0) {
                NavigationBar()
                Divider()
                    .background(Color.black)
                PlayerControlView(viewModel: viewModel)
                Divider()
                BottomBar(viewModel: viewModel)
            }
        }
    }
}

struct PlayerControlView: View {
    @ObservedObject var viewModel: PlayerViewModel

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Image(uiImage: viewModel.nowPlaying?.albumArt ?? UIImage())
                    .resizable()
                    .frame(width: min(geometry.size.width, geometry.size.height),
                           height: min(geometry.size.width, geometry.size.height))
                    .background(Color.gray.opacity(0.7))
                    .cornerRadius(16)
                    .scaledToFill()
                
                Slider(value: $viewModel.duration, in: 0...Double(viewModel.nowPlaying?.mediaInfo?.duration ?? 0)) {
                    viewModel.isEditSeeking = $0
                    if !$0 {
                        viewModel.seek(to: viewModel.duration)
                    }
                }
                HStack {
                    Text(viewModel.duration.dateFormatted())
                        .font(.system(size: 12))
                    Spacer()
                    Text(Double(viewModel.nowPlaying?.mediaInfo?.duration ?? 0).dateFormatted())
                        .font(.system(size: 12))
                }
                .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
                
                HStack(spacing: 4) {
                    if let bitdepth = viewModel.nowPlaying?.mediaInfo?.bitdepth {
                        Text("\(bitdepth)bit")
                    } else {
                        Text("-")
                    }

                    Text("/")

                    if let samplerate = viewModel.nowPlaying?.mediaInfo?.samplerate {
                        Text((samplerate > 1000 ? String(format: "%.1fk", Double(samplerate)/Double(1000)) : "\(samplerate)") + "Hz")
                    } else {
                        Text("-")
                    }
                }
                .padding(EdgeInsets(top: 32, leading: 8, bottom: 16, trailing: 8))
                
                Text(viewModel.nowPlaying?.mediaInfo?.title ?? "Title")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(viewModel.nowPlaying?.mediaInfo?.artist ?? "Artist")
                    .font(.title3)
                
                HStack(spacing: 36) {
                    Button(action: {
                        viewModel.skipPrev()
                    }, imageName: "reverse")
                    .frame(width: 50, height: 50)
                    
                    Button(action: {
                        switch viewModel.state {
                        case .initialized, .stopped:
                            viewModel.play()
                            break
                            
                        case .ready:
                            viewModel.play()
                            break
                            
                        case .paused:
                            viewModel.resume()
                            break
                            
                        case .playing:
                            viewModel.pause()
                            break
                            
                        default:
                            break
                        }
                    }, imageName: viewModel.state == .playing ? "pause" : "play" )
                    .frame(width: 50, height: 50)
                    
                    Button(action: {
                        viewModel.skipNext()

                    }, imageName: "forward")
                    .frame(width: 50, height: 50)
                }
                .padding(EdgeInsets(top: 8, leading: 8, bottom: 16, trailing: 8))
            }
        }
        .padding(24)
    }
}

struct NavigationBar: View {
    var body: some View {
        HStack {
            EmptyView()
        }
        .frame(height: 50)
    }
}

struct BottomBar: View {
    @ObservedObject var viewModel: PlayerViewModel

    var body: some View {
        HStack {
            NavigationLink(destination: EqualizerView(viewModel: viewModel)) {
                Image("equalizer")
                    .resizable()
                    .scaledToFit()
                    .padding(5)
                    .frame(width: 50, height: 50)
            }
            .padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
            Spacer()
            NavigationLink(destination: PlaylistView(viewModel: viewModel)) {
                Image("playlist")
                    .resizable()
                    .scaledToFit()
                    .padding(5)
                    .frame(width: 50, height: 50)
            }
            .padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
        }
    }
}

#Preview {
    PlayerView()
}
