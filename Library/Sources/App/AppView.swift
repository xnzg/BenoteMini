import ComposableArchitecture
import SwiftUI

public struct AppView: View {
    @State var store: StoreOf<AppFeature> = .init(initialState: .initialState, reducer: AppFeature())

    public init() {}

    public var body: some View {
        DocumentEditorView(store: store.scope(state: \.editor, action: AppFeature.Action.editor))
    }
}
