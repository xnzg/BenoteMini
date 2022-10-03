import BenoteModel
import ComposableArchitecture
import SwiftUI

struct NodeEditorView: View {
    var store: StoreOf<NodeEditor>
    var documentStore: StoreOf<DocumentEditor>

    var body: some View {
        WithViewStore(store) { viewStore in
            NodeEditorTextView(viewStore: viewStore, documentStore: documentStore)
                .padding(.leading, CGFloat(viewStore.level * 20))
                .padding()
                .background(Color.black.opacity(0.1))
        }
    }
}
