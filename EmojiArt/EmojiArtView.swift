//
//  ContentView.swift
//  EmojiArt
//
//  Created by Егор Пехота on 07.05.2021.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    @ObservedObject var document = EmojiArtDocument()
    @State var selectedEmojis: Set<EmojiArt.Emoji> = [] {
        didSet {
            print("\(selectedEmojis)\n")
        }
    }

    var body: some View {
        VStack {
            HStack {
                ForEach(EmojiArtDocument.palette.map { String($0) }, id: \.self) {emoji in
                    Text(emoji)
                        .font(Font.system(size: self.defaultEmojiSize))
                        .onDrag { return NSItemProvider(object: emoji as NSString) }
                }
                Text("\(zoomScale)")
            }
            .padding(.horizontal)
            HStack {
                Button("Load Background") {
                    document.backgroundURL = URL(string: "https://images.unsplash.com/photo-1567621301854-85b95d32bbf3?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1534&q=80")
                }
                Spacer()
                Button("Clear") {
                    clearDocument()
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
                    if self.isLoading {
                        Image(systemName: "hourglass").imageScale(.large).spinning()
                    } else {
                        ForEach(document.emojis) {emoji in
                            Text(emoji.text)
                                .font(animatableWithSize: emoji.fontSize * zoomScale)
                                .border(Color.black, width: selectedEmojis.contains(matching: emoji) ? 1 : 0 )
                                .scaleEffect(isDetectingLongPress ? 2 : 1)
                                .position(self.position(for: emoji, in: geometry.size))
                                .gesture(tapToSelect(emoji: emoji))
                                .gesture(selectionOffsetGesture())
                                .gesture(longTapToRemoveEmojiGesture(emoji: emoji))
                        }
                    }
//                    Text("+")
//                        .font(animatableWithSize: defaultEmojiSize * zoomScale)
//                        .position(self.centerOfScreen(in: geometry.size))
                }
                .clipped()
                .edgesIgnoringSafeArea([.horizontal,.bottom])
                .gesture(offsetGesture())
                .gesture(zoomGesture())
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
    
    var isLoading: Bool {
        document.backgroundURL != nil && document.backgroundImage == nil
    }
    
    @State private var steadyStateZoomScale: CGFloat = 1.0
    @GestureState private var gestureZoomScale: CGFloat = 1.0
    
    private var zoomScale: CGFloat {
        steadyStateZoomScale * gestureZoomScale
    }
    
    private func zoomGesture() -> some Gesture {
        MagnificationGesture()
            .updating($gestureZoomScale) { latestGestureScale, gestureZoomScale, transaction in
                if selectedEmojis.isEmpty {
                    gestureZoomScale = latestGestureScale
                } else {
                    for emoji in selectedEmojis {
                        document.scaleEmoji(emoji, by: gestureZoomScale)
                    }
                }
            }
            .onEnded { finalGestureScale in
                if selectedEmojis.isEmpty {
                    steadyStateZoomScale *= finalGestureScale
                } else {
                    for emoji in selectedEmojis {
                        document.scaleEmoji(emoji, by: finalGestureScale)
                    }
                }
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
    

    @GestureState private var gestureDragSelectionOffset: CGSize = .zero
    private func selectionOffsetGesture() -> some Gesture {
        DragGesture()
            .updating($gestureDragSelectionOffset) { latestDragValue, gestureDragSelectionOffset,transaction in
                gestureDragSelectionOffset = latestDragValue.translation / zoomScale
                print("gestureDragSelectionOffset is \(gestureDragSelectionOffset)")
                for emoji in selectedEmojis {
//                    withAnimation() {
                        document.moveEmoji(emoji, by: gestureDragSelectionOffset)
//                    }
                }
            }
            .onEnded { finalDragValue in
                for emoji in selectedEmojis {
//                    withAnimation() {
                        document.moveEmoji(emoji, by: finalDragValue.translation / zoomScale)
//                    }
                }
            }
    }

    private func tapToSelect(emoji: EmojiArt.Emoji) -> some Gesture {
       TapGesture(count: 1)
            .onEnded {
                selectedEmojis.toggleMatching(emoji)
            }
    }

    private func tapToDeselect() -> some Gesture {
        TapGesture(count: 1)
            .onEnded {
                selectedEmojis = []
            }
    }
    
    @GestureState private var isDetectingLongPress = false
    private func longTapToRemoveEmojiGesture(emoji: EmojiArt.Emoji) -> some Gesture {
        LongPressGesture()
            .onEnded {_ in
                document.removeEmoji(emoji)
            }
    }
    
    private func doubleTapToZoom(in size: CGSize) -> some Gesture {
        TapGesture(count: 2)
            .onEnded{
                withAnimation {
                    zoomToFit(document.backgroundImage, in: size)
                }
            }
            .exclusively(before: tapToDeselect())
    }
    
    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        if let image = image, image.size.width > 0, image.size.height > 0 {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            steadyStateZoomScale = min(hZoom,vZoom)
            steadyStatePanOffset = .zero
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
            document.backgroundURL = url
        }
        if !found {
            found = providers.loadObjects(ofType: String.self) {string in
                self.document.addEmoji(string, at: location, size: self.defaultEmojiSize)
            }
        }
        return found
    }
    
    private func clearDocument() {
        document.clearDocument()
        steadyStatePanOffset = .zero
        steadyStateZoomScale = 1.0
        selectedEmojis = []
    }
    private let defaultEmojiSize: CGFloat = 40
    
    private func centerOfScreen(in size: CGSize) -> CGPoint {
        let center = CGPoint(x: 0, y: 0)
        var location = CGPoint(x: center.x * zoomScale, y: center.y * zoomScale)
        location = CGPoint(x: location.x + size.width/2, y: location.y + size.height/2)
        location = CGPoint(x: location.x + panOffset.width, y: location.y + panOffset.height)
        return location
    }
}
