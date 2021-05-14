//
//  PalletteChooser.swift
//  EmojiArt
//
//  Created by Егор Пехота on 14.05.2021.
//

import SwiftUI

struct PalletteChooser: View {
   
    @ObservedObject var document: EmojiArtDocument
    
    @Binding var chosenPalette: String
    
    var body: some View {
        HStack {
            Stepper(
                onIncrement: {
                    self.chosenPalette = document.palette(after: chosenPalette)
                },
                onDecrement: {
                    self.chosenPalette = document.palette(before: chosenPalette)
                },
                label: {
                     EmptyView()
                })
            Text(document.paletteNames[chosenPalette] ?? "" )
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}
