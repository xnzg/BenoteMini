import App
import BenoteModel
import ComposableArchitecture
import SwiftUI

struct ContentView: View {
    @State var store: StoreOf<DocumentEditor> = .init(initialState: .initialState, reducer: DocumentEditor())

    var body: some View {
        ScrollView(.vertical) {
            DocumentEditorView(store: store)
        }
    }
}
