//
//  OptionalImage.swift
//  EmojiArt
//
//  Created by Егор Пехота on 07.05.2021.
//

import SwiftUI

struct OptionalImage: View {
    var uiImage: UIImage?
    
    var body: some View {
        Group {
            if uiImage != nil {
                Image(uiImage: uiImage!)
            }
        }
    }
}
