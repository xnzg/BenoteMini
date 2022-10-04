import BenoteModel
import ComposableArchitecture
import SwiftUI

struct NodeEditorView: View {
    var store: StoreOf<NodeEditor>
    var editorStore: StoreOf<DocumentEditor>

    var body: some View {
        WithViewStore(store) { viewStore in
            HStack(spacing: 0) {
                Button {
                    viewStore.send(.toggleCollapse, animation: .default)
                } label: {
                    let name = viewStore.collapseStatus == .collapsed ? "arrowtriangle.forward.fill" : "arrowtriangle.down.fill"
                    Image(systemName: name)
                        .frame(width: 30)
                }
                .buttonStyle(EmptyButtonStyle())
                .disabled(viewStore.collapseStatus == .leaf)
                .opacity(viewStore.collapseStatus == .leaf ? 0 : 1)

                Button {
                    ViewStore(editorStore).send(.setFocus(viewStore.id), animation: .default)
                } label: {
                    Image(systemName: "circle.fill")
                        .frame(width: 30)
                }
                .buttonStyle(EmptyButtonStyle())
                NodeEditorTextView(viewStore: viewStore, editorStore: editorStore)
            }
            .padding(.leading, CGFloat(viewStore.level * 30))
        }
        .contextMenu {
            let viewStore = ViewStore(editorStore)
            let id = ViewStore(store).id
            let isFavorite = viewStore.document.favorites.contains(id)
            Button {
                viewStore.send(isFavorite ? .unfavorite(id) : .favorite(id), animation: .default)
            } label: {
                Text(isFavorite ? "Unfavorite" : "Favorite")
            }
        }
    }
}

struct EmptyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}
