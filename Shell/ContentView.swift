import ComposableArchitecture
import SwiftUI

struct NodeFeature: ReducerProtocol {
    struct State: Equatable, Identifiable {
        var id: UUID
        var body: String
        var indentation: Int
    }

    enum Action: Equatable {
        case setText(String)
        case addSibling
        case incrLevel
        case decrLevel
    }

    func reduce(into state: inout State, action: Action) -> Effect<Action, Never> {
        Effect.none
    }
}

struct DocumentFeature: ReducerProtocol {
    struct State: Equatable {
        var nodes: [UUID: Node]
        var ordering: [Ordering]
    }

    enum Action: Equatable {
        case node(UUID, NodeFeature.Action)
    }

    func reduceSelf(into state: inout State, action: Action) -> Effect<Action, Never> {
        switch action {
        case let .node(nodeID, action):
            switch action {
            case .setText(let newValue):
                state.nodes[nodeID]!.body = newValue
            case .addSibling:
                state.addSibling(after: nodeID)
            case .incrLevel:
                state.incrLevel(nodeID: nodeID)
            case .decrLevel:
                state.decrLevel(nodeID: nodeID)
            }
        }
        return .none
    }

    @ReducerBuilderOf<DocumentFeature>
    var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            reduceSelf(into: &state, action: action)
        }
    }
}

extension DocumentFeature.State {
    func path(for nodeID: UUID) -> [Int] {
        var parentIDs = Array(sequence(first: nodeID, next: { nodes[$0]!.parent }))
        parentIDs.reverse()

        var current = ordering
        print(parentIDs)
        return parentIDs.map { id in
            let i = current.firstIndex { $0.id == id }!
            current = current[i].children
            return i
        }
    }

    mutating func modifyOrdering<T>(path: ArraySlice<Int>, body: (inout [Ordering]) -> T) -> T {
        func modify(path: ArraySlice<Int>, siblings: inout [Ordering]) -> T {
            guard let i = path.first else {
                return body(&siblings)
            }
            return modify(path: path.dropFirst(), siblings: &siblings[i].children)
        }
        return modify(path: ArraySlice(path), siblings: &ordering)
    }

    @discardableResult
    mutating func addSibling(after nodeID: UUID) -> UUID {
        let anchor = nodes[nodeID]!
        let path = path(for: nodeID)
        let node = Node(id: UUID(), body: "", parent: anchor.parent)
        nodes[node.id] = node
        modifyOrdering(path: path.dropLast()) {
            $0.insert(.init(id: node.id, children: []), at: path.last! + 1)
        }
        return node.id
    }

    mutating func incrLevel(nodeID: UUID) {
        let path = path(for: nodeID)
        guard let i = path.last, i > 0 else { return }
        let newParentID = modifyOrdering(path: path.dropLast()) { siblings in
            let x = siblings[i]
            siblings.remove(at: i)
            siblings[i - 1].children.append(x)
            return siblings[i - 1].id
        }
        nodes[nodeID]?.parent = newParentID
    }

    mutating func decrLevel(nodeID: UUID) {
        let path = path(for: nodeID)
        guard path.count > 1 else { return }

        let i = path[path.endIndex - 1]
        let j = path[path.endIndex - 2]
        let newChildrenIDs = modifyOrdering(path: path.dropLast(2)) { parentSiblings in
            let siblings = parentSiblings[j].children
            var x = siblings[i]
            let newChildren = siblings[(i + 1)...]
            x.children.append(contentsOf: newChildren)
            let newChildrenIDs = newChildren.map(\.id)

            parentSiblings[j].children.removeSubrange(i..<siblings.endIndex)
            parentSiblings.insert(x, at: j + 1)

            return newChildrenIDs
        }

        let parentID = nodes[nodeID]!.parent!
        let newParentID = nodes[parentID]!.parent
        nodes[nodeID]!.parent = newParentID

        for newChildID in newChildrenIDs {
            nodes[newChildID]!.parent = nodeID
        }
    }

    var list: IdentifiedArrayOf<NodeFeature.State> {
        var list: IdentifiedArrayOf<NodeFeature.State> = []
        func visit(ordering: Ordering, level: Int) {
            let id = ordering.id
            list.append(.init(id: id, body: nodes[id]!.body, indentation: level))
            for child in ordering.children {
                visit(ordering: child, level: level + 1)
            }
        }
        for child in ordering {
            visit(ordering: child, level: 0)
        }
        return list
    }
}

struct Node: Equatable, Identifiable {
    var id: UUID
    var body: String
    var parent: UUID?
}

struct Ordering: Equatable, Identifiable {
    var id: UUID
    var children: [Ordering]
}

struct AppState: Equatable {
    var nodes: [UUID: Node]
    var ordering: [Ordering]

    static let sample: AppState = {
        let node = Node(id: UUID(), body: "Hello, world")
        let ordering = Ordering(id: node.id, children: [])
        return .init(nodes: [node.id: node], ordering: [ordering])
    }()
}

struct BlockEditorRepn: UIViewRepresentable {
    @ObservedObject var viewStore: ViewStoreOf<NodeFeature>

    func makeCoordinator() -> Coordinator {
        .init(viewStore: viewStore)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = TextView()
        textView.isScrollEnabled = false
        textView.font = .preferredFont(forTextStyle: .body)
        textView.delegate = context.coordinator

        textView.onIncrLevel = {
            viewStore.send(.incrLevel)
        }
        textView.onDecrLevel = {
            viewStore.send(.decrLevel)
        }

        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != viewStore.state.body {
            uiView.text = viewStore.state.body
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        guard let width = proposal.width else { return nil }
        let height = uiView.sizeThatFits(.init(width: width, height: .infinity)).height
        return .init(width: width, height: height)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var viewStore: ViewStoreOf<NodeFeature>

        init(viewStore: ViewStoreOf<NodeFeature>) {
            self.viewStore = viewStore
        }

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            if text == "\n" {
                viewStore.send(.addSibling)
                return false
            }
            return true
        }

        func textViewDidChange(_ textView: UITextView) {
            if viewStore.state.body != textView.text {
                viewStore.send(.setText(textView.text))
            }
        }
    }
}

final class TextView: UITextView {
    var onIncrLevel: (() -> Void)!
    var onDecrLevel: (() -> Void)!

    @objc
    func incrLevel(_ sender: Any) {
        onIncrLevel()
    }

    @objc
    func decrLevel(_ sender: Any) {
        onDecrLevel()
    }

    override var keyCommands: [UIKeyCommand]? {
        var list = super.keyCommands ?? []
        let tab = UIKeyCommand(input: "\t", modifierFlags: [], action: #selector(incrLevel(_:)))
        tab.wantsPriorityOverSystemBehavior = true
        list.append(tab)

        let detab = UIKeyCommand(input: "\t", modifierFlags: [.shift], action: #selector(decrLevel(_:)))
        tab.wantsPriorityOverSystemBehavior = true
        list.append(detab)
        return list
    }
}

struct BlockEditor: View {
    var store: StoreOf<NodeFeature>

    var body: some View {
        WithViewStore(store) { viewStore in
            BlockEditorRepn(viewStore: viewStore)
                .padding(.leading, CGFloat(viewStore.indentation * 20))
                .padding()
                .background(Color.black.opacity(0.1))
        }
    }
}

struct DocumentView: View {
    var store: StoreOf<DocumentFeature>

    var body: some View {
        let forEachable = store.scope { state in
            state.list
        } action: { (blockID, action) in
            .node(blockID, action)
        }
        LazyVStack {
            ForEachStore(forEachable) { store in
                BlockEditor(store: store)
            }
        }
        .padding()
    }
}

struct ContentView: View {
    @State var store: StoreOf<DocumentFeature> = .init(initialState: Self.initialState, reducer: DocumentFeature())

    var body: some View {
        ScrollView(.vertical) {
            DocumentView(store: store)
        }
    }

    static var initialState: DocumentFeature.State {
        let node = Node(id: UUID(), body: "Hello, world!")
        return .init(nodes: [node.id: node], ordering: [.init(id: node.id, children: [])])
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
