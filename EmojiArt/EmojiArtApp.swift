//
//  EmojiArtApp.swift
//  EmojiArt
//
//  Created by Егор Пехота on 07.05.2021.
//

import SwiftUI

@main
struct EmojiArtApp: App {
    let store: EmojiArtDocumentStore
    init() {
        self.store = EmojiArtDocumentStore(named: "Emoji Art")
    }
    var body: some Scene {
        WindowGroup {
            EmojiArtDocumentChooser().environmentObject(store)
        }
    }
}
