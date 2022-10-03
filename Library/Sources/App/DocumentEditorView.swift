import BenoteModel
import ComposableArchitecture
import SwiftUI

public struct DocumentEditorView: View {
    public var store: StoreOf<DocumentEditor>

    public init(store: StoreOf<DocumentEditor>) {
        self.store = store
    }

    public var body: some View {
        let childStores = store.scope { state in
            state.visibleNodes()
        } action: { (nodeID, action) in
            .node(nodeID, action)
        }
        LazyVStack {
            ForEachStore(childStores) { store in
                NodeEditorView(store: store, documentStore: self.store)
            }
        }
        .padding()
    }
}
