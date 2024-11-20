//
//  EqualizerView.swift
//  Sample
//
//  Created by debugholic on 11/7/24.
//  Copyright © 2024 Sidekick-Academy. All rights reserved.
//

import SwiftUI

extension AudioEqualizerValue: Identifiable {
    
}

struct EqualizerView: View {
    @ObservedObject var viewModel: PlayerViewModel
    
    var body: some View {
        List {
            Toggle(isOn: $viewModel.isEqualizerEnabled, label: {
                Text("EQ 사용")
            })
            
            if viewModel.isEqualizerEnabled {
                ForEach($viewModel.equalizer.values, id: \.band) { $value in
                    Stepper("\(value.band): \(value.gain)", value: $value.gain, in: AudioEqualizerValue.minGain...AudioEqualizerValue.maxGain) {
                        if !$0 { viewModel.equalizer.changeFilter() }
                    }
                }
            }
        }
    }
}
