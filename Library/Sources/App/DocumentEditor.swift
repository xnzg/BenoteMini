import BenoteModel
import ComposableArchitecture
import Foundation

public struct NodeEditor: ReducerProtocol {
    public typealias State = NodeViewState

    public enum Action: Equatable {
        case setText(String)
        case toggleCollapse
        case addSibling
        case increaseLevel
        case decreaseLevel
        case delete
    }

    public func reduce(into state: inout State, action: Action) -> Effect<Action, Never> {
        Effect.none
    }
}

public struct DocumentEditor: ReducerProtocol {
    public struct State: Equatable {
        public var document: Document
        public var focus: UUID?
    }

    public enum Action: Equatable {
        case node(UUID, NodeEditor.Action)
        case setFocus(UUID?)
        case favorite(UUID)
        case unfavorite(UUID)
    }

    public init() {}

    private func reduceDocument(into state: inout Document, nodeID: UUID, action: NodeEditor.Action) {
        switch action {
        case .setText(let newValue):
            state[nodeID].text = newValue
        case .toggleCollapse:
            state[nodeID].isCollapsed.toggle()
        case .addSibling:
            state.append(.init(text: ""), after: nodeID)
        case .increaseLevel:
            state.increaseLevel(nodeID: nodeID)
        case .decreaseLevel:
            state.decreaseLevel(nodeID: nodeID)
        case .delete:
            state.delete(nodeID: nodeID)
        }
    }

    public func reduce(into state: inout State, action: Action) -> Effect<Action, Never> {
        switch action {
        case .node(let nodeID, let action):
            reduceDocument(into: &state.document, nodeID: nodeID, action: action)
        case .setFocus(let focus):
            state.focus = focus
        case .favorite(let nodeID):
            state.document.favorite(nodeID)
        case .unfavorite(let nodeID):
            state.document.unfavorite(nodeID)
        }
        return .none
    }
}
