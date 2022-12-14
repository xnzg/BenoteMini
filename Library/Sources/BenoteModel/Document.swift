import IdentifiedCollections
import Foundation

public struct NodeProps: Equatable, Identifiable {
    public var id: UUID
    public var parent: UUID
    public var text: String
    public var isCollapsed: Bool

    public init(id: UUID = UUID(), parent: UUID = NodeTree.rootID, text: String, isCollapsed: Bool = false) {
        self.id = id
        self.parent = parent
        self.text = text
        self.isCollapsed = isCollapsed
    }
}

public struct NodeTree: Equatable, Identifiable {
    public fileprivate(set) var id: UUID
    public fileprivate(set) var children: [NodeTree]

    public typealias UpdateParent = (UUID, UUID) -> Void

    public subscript(_ path: ArraySlice<Int>) -> NodeTree {
        get {
            guard let i = path.first else { return self }
            return children[i][path.dropFirst()]
        }
        set {
            guard let i = path.first else {
                self = newValue
                return
            }
            children[i][path.dropFirst()] = newValue
        }
    }

    public static let rootID = UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))

    public static func fresh(id: UUID) -> Self {
        .init(id: id, children: [])
    }

    public static var root: Self = fresh(id: rootID)
}

public struct Document: Equatable {
    public private(set) var nodes: [UUID: NodeProps] = [:]
    public private(set) var tree: NodeTree = .root
    public private(set) var favorites: [UUID] = []

    public static var initialState: Self = {
        var doc = Self()
        doc.append(.init(text: "Hello, world!"), to: NodeTree.rootID)
        return doc
    }()
}

extension Document {
    public subscript(nodeID: UUID) -> NodeProps {
        get {
            nodes[nodeID]!
        }
        set {
            let oldValue = nodes[nodeID]!
            assert(oldValue.id == newValue.id)
            assert(oldValue.parent == newValue.parent)
            nodes[nodeID] = newValue
        }
    }

    func path(for nodeID: UUID) -> ArraySlice<Int> {
        guard nodeID != NodeTree.rootID else {
            return ArraySlice([])
        }
        var parentIDs = Array(sequence(first: nodeID, next: {
            let parentID = nodes[$0]!.parent
            return parentID == NodeTree.rootID ? nil : parentID
        }))
        parentIDs.reverse()

        var current = tree
        let indices = parentIDs.map { id in
            let i = current.children.firstIndex { $0.id == id }!
            current = current.children[i]
            return i
        }
        return ArraySlice(indices)
    }

    public mutating func append(_ child: NodeProps, to parentID: UUID) {
        assert(nodes[child.id] == nil)

        var child = child
        child.parent = parentID
        nodes[child.id] = child

        let parentPath = path(for: parentID)
        tree[parentPath].children.append(.fresh(id: child.id))
    }

    public mutating func append(_ child: NodeProps, after siblingID: UUID) {
        assert(nodes[child.id] == nil)

        var child = child
        child.parent = nodes[siblingID]!.parent
        nodes[child.id] = child

        let siblingPath = path(for: siblingID)
        let parentPath = siblingPath.dropLast()
        let siblingIndex = siblingPath.last!
        tree[parentPath].children.insert(.fresh(id: child.id), at: siblingIndex + 1)
    }

    public func canIncreaseLevel(nodeID: UUID) -> Bool {
        let path = path(for: nodeID)
        guard let i = path.last, i > 0 else { return false }
        return true
    }

    public mutating func increaseLevel(nodeID: UUID) {
        assert(canIncreaseLevel(nodeID: nodeID))

        let path = path(for: nodeID)
        let i = path.last!
        let parentPath = path.dropLast()

        var parentSubtree = tree[parentPath]
        parentSubtree.children[i - 1].children.append(parentSubtree.children[i])
        parentSubtree.children.remove(at: i)
        tree[parentPath] = parentSubtree

        nodes[nodeID]!.parent = parentSubtree.children[i - 1].id
    }

    public func canDecreaseLevel(nodeID: UUID) -> Bool {
        let path = path(for: nodeID)
        return path.count > 1
    }

    public mutating func decreaseLevel(nodeID: UUID) {
        assert(canDecreaseLevel(nodeID: nodeID))

        let path = path(for: nodeID)
        let i = path[path.endIndex - 1]
        let j = path[path.endIndex - 2]
        let newParentPath = path.dropLast(2)

        var parentSubtree = tree[newParentPath]
        var selfSubtree = parentSubtree.children[j].children[i]

        let newChildren = parentSubtree.children[j].children[(i + 1)...]
        for child in newChildren {
            nodes[child.id]!.parent = nodeID
        }
        parentSubtree.children[j].children.removeSubrange(i...)
        selfSubtree.children.append(contentsOf: newChildren)
        parentSubtree.children.insert(selfSubtree, at: j + 1)
        tree[newParentPath] = parentSubtree

        nodes[nodeID]!.parent = parentSubtree.id
    }

    public mutating func collapse(nodeWithID nodeID: UUID) {
        nodes[nodeID]?.isCollapsed = true
    }

    public mutating func expand(nodeWithID nodeID: UUID) {
        nodes[nodeID]?.isCollapsed = false
    }

    public mutating func favorite(_ nodeID: UUID) {
        guard nodes[nodeID] != nil else { return }
        favorites.append(nodeID)
    }

    public mutating func unfavorite(_ nodeID: UUID) {
        favorites.removeAll { $0 == nodeID }
    }

    public mutating func delete(nodeID: UUID) {
        var toRemove: Set<UUID> = []
        let path = path(for: nodeID)
        func visit(_ node: NodeTree) {
            toRemove.insert(node.id)
            for child in node.children {
                visit(child)
            }
        }
        visit(tree[path])

        for id in toRemove {
            nodes.removeValue(forKey: id)
        }
        favorites.removeAll { toRemove.contains($0) }

        let i = path.last!
        tree[path.dropLast()].children.remove(at: i)
    }
}

public struct NodeViewState: Identifiable, Equatable {
    public var props: NodeProps
    public var level: Int
    public var collapseStatus: CollapseStatus

    public var id: UUID { props.id }

    public enum CollapseStatus: Hashable {
        case leaf
        case collapsed
        case expanded
    }
}

extension Document {
    public func visibleNodes(focus: UUID? = nil) -> IdentifiedArrayOf<NodeViewState> {
        var list: IdentifiedArrayOf<NodeViewState> = []

        func visit(tree: NodeTree, level: Int) {
            let node = nodes[tree.id]!
            let status: NodeViewState.CollapseStatus
            if tree.children.isEmpty {
                status = .leaf
            } else {
                status = node.isCollapsed ? .collapsed : .expanded
            }

            list.append(.init(props: node, level: level, collapseStatus: status))
            guard status == .expanded else { return }
            for child in tree.children {
                visit(tree: child, level: level + 1)
            }
        }

        var target = tree
        if let focus {
            target = tree[path(for: focus)]
        }
        for child in target.children {
            visit(tree: child, level: 0)
        }
        return list
    }
}
