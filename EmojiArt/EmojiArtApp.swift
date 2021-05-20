//
//  EmojiArtApp.swift
//  EmojiArt
//
//  Created by Егор Пехота on 07.05.2021.
//

import SwiftUI

@main
struct EmojiArtApp: App {
    var body: some Scene {
        WindowGroup {
            EmojiArtDocumentView(document: EmojiArtDocument())
        }
    }
}
