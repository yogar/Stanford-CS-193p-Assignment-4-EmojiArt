//
//  Grid.swift
//  HarvardCourse_01
//
//  Created by Егор Пехота on 07.03.2021.
//

import SwiftUI

// Displays View items in a grid.

struct Grid<Item, ID, ItemView>: View where ID: Hashable, ItemView: View {
    // Items array.
    private var items: [Item]
    private var id: KeyPath<Item, ID>
    
    // Returns view for an item.
    private var viewForItem: (Item) -> ItemView
    
    // Returns `Grid<Item, ItemView>` instance. Initializes values for `self.items` with array of `Item` and `self.viewForItem` with a closure.
    init(_ items: [Item], id: KeyPath<Item,ID>, viewForItem: @escaping (Item) -> ItemView) {
        self.items = items
        self.id = id
        self.viewForItem = viewForItem
    }
     
    var body: some View {
        GeometryReader { geometry in
            self.body(for: GridLayout(itemCount: self.items.count, in: geometry.size))
        }
    }
     
    private func body(for layout: GridLayout) -> some View {
        ForEach(items, id: id) {item in
            self.body(for: item, in:layout )
        }
    }
    
    private func body(for item: Item, in layout: GridLayout) -> some View {
        let index = items.firstIndex(where: { item[keyPath: id] == $0[keyPath: id] })
        return Group {
            if index != nil {
                viewForItem(item)
                    .frame(width: layout.itemSize.width, height: layout.itemSize.height)
                    .position(layout.location(ofItemAt: index!))
            }
        }
    }
}
