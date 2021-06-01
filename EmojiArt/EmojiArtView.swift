//
//  ContentView.swift
//  EmojiArt
//
//  Created by Егор Пехота on 07.05.2021.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    @ObservedObject var document: EmojiArtDocument
    @State var selectedEmojis: Set<EmojiArt.Emoji> = [] {
        didSet {
            print("\(selectedEmojis)\n")
        }
    }
    @State private var chosenPallette: String = ""
    
    init(document: EmojiArtDocument) {
        self.document = document
        _chosenPallette = State(wrappedValue: self.document.defaultPalette)
    }

    var body: some View {
        VStack(alignment: .leading) {
            PalletteChooser(document: document, chosenPalette: $chosenPallette)
            ScrollView(.horizontal) {
                HStack {
                    ForEach(chosenPallette.map { String($0) }, id: \.self) {emoji in
                        Text(emoji)
                            .font(Font.system(size: self.defaultEmojiSize))
                            .onDrag { return NSItemProvider(object: emoji as NSString) }
                    }
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
                }
                .clipped()
                .edgesIgnoringSafeArea([.horizontal,.bottom])
                .gesture(offsetGesture())
                .gesture(zoomGesture())
//                .onReceive(document.$backgroundImage) { image in
//                    zoomToFit(image, in: geometry.size)
//                }
                .onDrop(of: ["public.image","public.text"], isTargeted: nil) {providers, location in
                    var location = geometry.convert(location, from: .global)
                    location = CGPoint(x: location.x - geometry.size.width / 2, y: location.y - geometry.size.height / 2)
                    location = CGPoint(x: location.x - panOffset.width, y: location.y - panOffset.height)
                    location = CGPoint(x: location.x / zoomScale, y: location.y / zoomScale )
                    return self.drop(providers: providers, at: location)
                }
                .alert(isPresented: $confirmBackgroundPaste, content: {
                    return Alert(
                        title: Text("Paste Background"),
                        message: Text("Replace your background url with \(UIPasteboard.general.url?.absoluteString ?? "nothing")?"),
                        primaryButton: .default(Text("Ok")) {
                            document.backgroundURL = UIPasteboard.general.url
                        },
                        secondaryButton: .cancel()
                    )
                })
            }
            .zIndex(-1)
        }
        .navigationBarItems(trailing:
            HStack {
                Button(action: {
                    if let url = UIPasteboard.general.url, url != document.backgroundURL {
                        confirmBackgroundPaste = true
                    } else {
                        explainBackgroundPaste = true
                    }
                }, label: {
                    Image(systemName: "doc.on.clipboard")
                        .alert(isPresented: $explainBackgroundPaste, content: {
                            return Alert(
                                title: Text("Paste Background"),
                                message: Text("Copy image of the URL to the clipboard and touch this button to make it the background of your document"),
                                dismissButton: .default(Text("Ok")))
                        })
                })
                Button("Clear") {
                    clearDocument()
                }
            }
        )
    }
    
    @State private var explainBackgroundPaste = false
    @State private var confirmBackgroundPaste = false
    
    var isLoading: Bool {
        document.backgroundURL != nil && document.backgroundImage == nil
    }

    @GestureState private var gestureZoomScale: CGFloat = 1.0
    
    private var zoomScale: CGFloat {
        document.steadyStateZoomScale * gestureZoomScale
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
                    document.steadyStateZoomScale *= finalGestureScale
                } else {
                    for emoji in selectedEmojis {
                        document.scaleEmoji(emoji, by: finalGestureScale)
                    }
                }
            }
    }
    
    @GestureState private var gesturePanOffset: CGSize = .zero
    
    private var panOffset: CGSize {
        (document.steadyStatePanOffset + gesturePanOffset) * zoomScale
    }
    
    private func offsetGesture() -> some Gesture {
        DragGesture()
            .updating($gesturePanOffset) { latestDragValue, gesturePanOffset, transaction in
                gesturePanOffset = latestDragValue.translation / zoomScale
            }
            .onEnded {finalGestureDragValue in
                document.steadyStatePanOffset = document.steadyStatePanOffset + finalGestureDragValue.translation / zoomScale
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
        if let image = image, image.size.width > 0, image.size.height > 0, size.height > 0, size.width > 0 {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            document.steadyStateZoomScale = min(hZoom,vZoom)
            document.steadyStatePanOffset = .zero
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
