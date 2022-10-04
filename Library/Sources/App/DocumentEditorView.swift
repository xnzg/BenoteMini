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
            state.document.visibleNodes(focus: state.focus)
        } action: { (nodeID, action) in
            .node(nodeID, action)
        }
        ScrollView(.vertical) {
            // We have to use VStack here since LazyVStack will give odd results
            // when the list updates. This is not a scalable solution.
            VStack {
                WithViewStore(store) { viewStore in
                    if let focus = viewStore.focus {
                        HStack {
                            Text(viewStore.document.nodes[focus]!.text)
                                .font(.largeTitle)
                            Spacer()
                            Button {
                                viewStore.send(.setFocus(nil), animation: .default)
                            } label: {
                                Image(systemName: "xmark")
                            }
                        }
                    }
                }

                ForEachStore(childStores) { store in
                    NodeEditorView(store: store, editorStore: self.store)
                }
            }
            .padding()
        }
    }
}
