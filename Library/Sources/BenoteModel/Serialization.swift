import Foundation

struct SerializableDocument: Codable {
    private(set) var version: UInt64 = 1
    let nodes: [String: SerializableNode]
}

struct SerializableNode: Equatable, Codable {
    var parent: UUID?
    var previous: UUID?
    var text: String
    var isCollapsed: Bool
}

extension SerializableDocument {
    static func from(_ document: Document) -> Self {
        var nodes: [String: SerializableNode] = [:]

        func visitChildren(tree: NodeTree) {
            if let first = tree.children.first {
                visit(tree: first, previous: nil)
            }

            for (previous, current) in zip(tree.children, tree.children.dropFirst()) {
                visit(tree: current, previous: previous.id)
            }
        }

        func visit(tree: NodeTree, previous: UUID?) {
            let node = document.nodes[tree.id]!
            var parent: UUID?
            if previous == nil, node.parent != NodeTree.rootID {
                parent = node.parent
            }

            nodes[node.id.uuidString] = SerializableNode(
                parent: parent,
                previous: previous,
                text: node.text,
                isCollapsed: node.isCollapsed)
            visitChildren(tree: tree)
        }

        visitChildren(tree: document.tree)

        return .init(nodes: nodes)
    }

    func document() -> Document {
        var document = Document()

        func visit(_ nodeID: UUID) -> Bool {
            guard document.nodes[nodeID] == nil else { return true }
            guard let snode = nodes[nodeID.uuidString] else { return false }

            let node = NodeProps(
                id: nodeID,
                text: snode.text,
                isCollapsed: snode.isCollapsed)

            if let previous = snode.previous {
                guard visit(previous) else { return false }
                document.append(node, after: previous)
            } else if let parent = snode.parent {
                guard visit(parent) else { return false }
                document.append(node, to: parent)
            } else {
                document.append(node, to: NodeTree.rootID)
            }

            return true
        }

        for nodeID in nodes.keys {
            guard let nodeID = UUID(uuidString: nodeID) else { continue }
            _ = visit(nodeID)
        }

        return document
    }
}

extension Document {
    public init(data: Data) throws {
        let decoder = JSONDecoder()
        let sdoc = try decoder.decode(SerializableDocument.self, from: data)
        self = sdoc.document()
    }

    public func encode() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [
            .prettyPrinted,
            // Make the resulting JSON more friendly to Git.
            .sortedKeys
        ]
        return try encoder.encode(SerializableDocument.from(self))
    }
}
