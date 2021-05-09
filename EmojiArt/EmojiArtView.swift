//
//  ContentView.swift
//  EmojiArt
//
//  Created by Егор Пехота on 07.05.2021.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    @ObservedObject var document = EmojiArtDocument()
    @State var selectedEmojis: Set<EmojiArt.Emoji> = []

    var body: some View {
        VStack {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(EmojiArtDocument.palette.map { String($0) }, id: \.self) {emoji in
                        Text(emoji)
                            .font(Font.system(size: self.defaultEmojiSize))
                            .onDrag { return NSItemProvider(object: emoji as NSString) }
                    }
                }
            }
            .padding(.horizontal)
            HStack {
                Button("Load Background") {
                    document.setBackgroundURL(URL(string: "https://images.unsplash.com/photo-1567621301854-85b95d32bbf3?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1534&q=80"))
                }
                Spacer()
                Button("Clear") {
                    document.clearDocument()
                }
            }
            .padding()
            GeometryReader {geometry in
                ZStack {
                    Color.white.overlay(
                        OptionalImage(uiImage: document.backgroundImage)
                            .scaleEffect(zoomScale)
                            .offset(panOffset)
                    )
                    .gesture(doubleTapToZoom(in: geometry.size))
                    ForEach(document.emojis) {emoji in
                        Text(emoji.text)
                            .font(animatableWithSize: emoji.fontSize * zoomScale)
                            .border(/*@START_MENU_TOKEN@*/Color.black/*@END_MENU_TOKEN@*/, width: selectedEmojis.contains(emoji) ? 1 : 0 )
                            .position(self.position(for: emoji, in: geometry.size))
                            .onTapGesture {
                               if !selectedEmojis.insert(emoji).inserted {
                                    selectedEmojis.remove(emoji)
                                }
                            }
                    }
                }
                .clipped()
                .gesture(offsetGesture())
                .gesture(zoomGesture())
                .edgesIgnoringSafeArea([.horizontal,.bottom])
                .onDrop(of: ["public.image","public.text"], isTargeted: nil) {providers, location in
                    var location = geometry.convert(location, from: .global)
                    location = CGPoint(x: location.x - geometry.size.width / 2, y: location.y - geometry.size.height / 2)
                    location = CGPoint(x: location.x - panOffset.width, y: location.y - panOffset.height)
                    location = CGPoint(x: location.x / zoomScale, y: location.y / zoomScale )
                    return self.drop(providers: providers, at: location)
                }
            }
        }
    }
    
    @State private var steadyStateZoomScale: CGFloat = 1.0
    @GestureState private var gestureZoomScale: CGFloat = 1.0
    
    private var zoomScale: CGFloat {
        steadyStateZoomScale * gestureZoomScale
    }
    
    private func zoomGesture() -> some Gesture {
        MagnificationGesture()
            .updating($gestureZoomScale) { latestGestureScale, gestureZoomScale, transaction in
                gestureZoomScale = latestGestureScale
            }
            .onEnded { finalGestureScale in
                steadyStateZoomScale *= finalGestureScale
            }
    }
    
    @State private var steadyStatePanOffset: CGSize = .zero
    @GestureState private var gesturePanOffset: CGSize = .zero
    
    private var panOffset: CGSize {
        (steadyStatePanOffset + gesturePanOffset) * zoomScale
    }
    
    private func offsetGesture() -> some Gesture {
        DragGesture()
            .updating($gesturePanOffset) { latestDragValue, gesturePanOffset, transaction in
                gesturePanOffset = latestDragValue.translation / zoomScale
            }
            .onEnded {finalGestureDragValue in
                steadyStatePanOffset = steadyStatePanOffset + finalGestureDragValue.translation / zoomScale
            }
        
    }

    private func doubleTapToZoom(in size: CGSize) -> some Gesture {
        TapGesture(count: 2)
            .onEnded{
                withAnimation {
                    zoomToFit(document.backgroundImage, in: size)
                }
            }
    }
    
    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        if let image = image, image.size.width > 0, image.size.height > 0 {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            steadyStatePanOffset = .zero
            steadyStateZoomScale = min(hZoom,vZoom)
        }
    }
    
    // Converts coordinates from coordinate system with 0,0 in the center of the screen to iOS coordinate system with 0,0 in left upper corner of the screen
    private func position(for emoji: EmojiArt.Emoji, in size: CGSize) -> CGPoint {
        var location = emoji.location
        location = CGPoint(x: location.x * zoomScale, y: location.y * zoomScale)
        location = CGPoint(x: location.x + size.width/2, y: location.y + size.height/2)
        location = CGPoint(x: location.x + panOffset.width, y: location.y + panOffset.height)
        return location
    }
    
    
    private func drop(providers: [NSItemProvider], at location: CGPoint) -> Bool {
        var found = providers.loadFirstObject(ofType: URL.self) {url in
            print("dropped \(url)")
            document.setBackgroundURL(url)
        }
        if !found {
            found = providers.loadObjects(ofType: String.self) {string in
                self.document.addEmoji(string, at: location, size: self.defaultEmojiSize)
            }
        }
        return found
    }
    
    private let defaultEmojiSize: CGFloat = 40
}
