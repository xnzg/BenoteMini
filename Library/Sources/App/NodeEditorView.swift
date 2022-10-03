import BenoteModel
import ComposableArchitecture
import SwiftUI

struct NodeEditorView: View {
    var store: StoreOf<NodeEditor>
    var documentStore: StoreOf<DocumentEditor>

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

                } label: {
                    Image(systemName: "circle.fill")
                        .frame(width: 30)
                }
                .buttonStyle(EmptyButtonStyle())
                NodeEditorTextView(viewStore: viewStore, documentStore: documentStore)
            }
            .padding(.leading, CGFloat(viewStore.level * 30))
        }
    }
}

struct EmptyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}
