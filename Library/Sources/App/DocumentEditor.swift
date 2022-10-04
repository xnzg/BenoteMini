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
    }

    public func reduce(into state: inout State, action: Action) -> Effect<Action, Never> {
        Effect.none
    }
}

public struct DocumentEditor: ReducerProtocol {
    public typealias State = Document

    public enum Action: Equatable {
        case node(UUID, NodeEditor.Action)
    }

    public init() {}

    public func reduce(into state: inout State, action: Action) -> Effect<Action, Never> {
        guard case let .node(nodeID, action) = action,
              state.nodes[nodeID] != nil
        else { return Effect.none }

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
        }
        return .none
    }
}
