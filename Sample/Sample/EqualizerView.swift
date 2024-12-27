//
//  EqualizerView.swift
//  Sample
//
//  Created by debugholic on 11/7/24.
//  Copyright © 2024 Sidekick-Academy. All rights reserved.
//

import SwiftUI

struct EqualizerView: View {
    @ObservedObject var viewModel: PlayerViewModel
    
    var body: some View {
        List {
            Toggle(isOn: $viewModel.isEqualizerEnabled) {
                Text("EQ 사용")
            }

            if viewModel.isEqualizerEnabled {
                ForEach($viewModel.equalizerValues, id: \.band) { $value in
                    VStack {
                        HStack {
                            Text((value.band >= 1000) ? "\(NSNumber(value: value.band / 1000))kHz" : "\(NSNumber(value: value.band))Hz")
                                .frame(width: 70, alignment: .leading)
                            Text("\(value.gain)dB")
                                .frame(width: 60, alignment: .leading)
                            Slider(value: .convert($value.gain), in: Double(AudioEqualizerValue.minGain)...Double(AudioEqualizerValue.maxGain)) {
                                if !$0 {
                                    viewModel.tune()
                                }
                            }
                                
                        }
                        HStack {
                            Text("Q-Factor:")
                                .frame(width: 80, alignment: .leading)
                            Stepper("\(NSNumber(value: value.q))", value: $value.q, in: 0...10) { _ in
                                viewModel.tune()
                            }
                        }
                    }
                }
            }
        }
    }
}

public extension Binding {
    static func convert<TInt, TFloat>(_ intBinding: Binding<TInt>) -> Binding<TFloat>
    where TInt:   BinaryInteger,
          TFloat: BinaryFloatingPoint {
        Binding<TFloat> (
            get: { TFloat(intBinding.wrappedValue) },
            set: { intBinding.wrappedValue = TInt($0) }
        )
    }

    static func convert<TFloat, TInt>(_ floatBinding: Binding<TFloat>) -> Binding<TInt>
    where TFloat: BinaryFloatingPoint,
          TInt:   BinaryInteger {
        Binding<TInt> (
            get: { TInt(floatBinding.wrappedValue) },
            set: { floatBinding.wrappedValue = TFloat($0) }
        )
    }
}
