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
    @State private var showPaletteEditor = false
    
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
            Image(systemName: "keyboard")
                .imageScale(.large)
                .onTapGesture {
                    self.showPaletteEditor = true
                }
                .popover(isPresented: $showPaletteEditor) {
                    PaletteEditor(chosenPalette: $chosenPalette,isShowing: $showPaletteEditor)
                        .environmentObject(document)
                        .frame(minWidth: 300,  minHeight: 500)
                }
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}


struct PaletteEditor: View {
    @Binding var chosenPalette: String
    @Binding var isShowing: Bool
    @EnvironmentObject var document: EmojiArtDocument
    
    @State private var paletteName: String = ""
    @State private var emojisToAdd: String = ""
    
    
    var body: some View {
        VStack(spacing: 0){
            ZStack {
                Text("Palette Editor").font(.headline).padding()
                HStack {
                    Spacer()
                    Button(action:{
                        isShowing = false
                    }, label: { Text("Done") }).padding()
                }
            }
            Divider()
            Form {
                Section {
                    TextField("Palette Name",text: $paletteName, onEditingChanged: { began in
                        if !began {
                            document.renamePalette(chosenPalette, to: paletteName)
                        }
                    })
                    TextField("Add Emoji",text: $emojisToAdd, onEditingChanged: { began in
                        if !began {
                            chosenPalette = document.addEmoji(emojisToAdd, toPalette: chosenPalette)
                            emojisToAdd = ""
                        }
                    })
                }
                Section(header: Text("Remove Emoji")) {
                    Grid(chosenPalette.map { String($0) }, id: \.self) { emoji in
                        Text(emoji)
                            .font(Font.system(size: self.fontSize))
                            .onTapGesture {
                                chosenPalette = document.removeEmoji(emoji, fromPalette: chosenPalette)
                            }
                    }
                    .frame(height: height)
                }
            }
        }
        .onAppear { paletteName = document.paletteNames[chosenPalette] ?? "" }
    }
    
    
    // MARK: - Drawing Constants
    
    var height: CGFloat {
        CGFloat(( chosenPalette.count - 1) / 6) * 70 + 70
    }
    
    let fontSize: CGFloat = 40
}
