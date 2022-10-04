import BenoteModel
import ComposableArchitecture
import SwiftUI

struct FavoritesView: View {
    var store: StoreOf<DocumentEditor>

    var body: some View {
        WithViewStore(store) { viewStore in
            VStack(alignment: .leading, spacing: 16) {
                Button {
                    viewStore.send(.setFocus(nil), animation: .default)
                } label: {
                    Text("Root")
                        .font(.headline)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Favorites")
                        .font(.headline)

                    ForEach(viewStore.document.favoriteList, id: \.0) { (id, text) in
                        Button {
                            viewStore.send(.setFocus(id), animation: .default)
                        } label: {
                            Text(text)
                        }
                    }
                }
            }
        }
        .padding()
        .buttonStyle(EmptyButtonStyle())
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

extension Document {
    var favoriteList: [(UUID, String)] {
        favorites.compactMap {
            guard let text = nodes[$0]?.text else { return nil }
            return ($0, text)
        }
    }
}
