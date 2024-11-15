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
        Toggle(isOn: $viewModel.isEqualizerEnabled, label: {
            Text("EQ 사용")
        })
    }
}
