import XCTest
@testable import BenoteModel

private extension Document {
    func id(of text: String) -> UUID? {
        nodes.first {
            $0.value.text == text
        }?.key
    }

    func checkAncestor(forNodeWihtID nodeID: UUID) {
        XCTAssertEqual(tree[path(for: nodeID)].id, nodeID)
    }
}

final class DocumentTests: XCTestCase {
    func parse(_ input: String) -> Document {
        let list: [(Int, String)] = input.split(separator: "\n")
            .map { line in
                let level = line.prefix { $0 == " " }.count
                let text = line.drop { $0 == " " }
                return (level, String(text))
            }

        var stack: [UUID] = [NodeTree.rootID]
        var current: Int { stack.count - 1 }
        var parent: UUID { stack[current] }
        var lastID: UUID = NodeTree.rootID
        var document = Document()

        for (level, text) in list {
            let id = UUID()
            defer { lastID = id }

            if level > current {
                precondition(level == current + 1)
                stack.append(lastID)
            } else if level < current {
                precondition(level == current - 1)
                stack.removeLast()
            }

            document.append(.init(id: id, parent: parent, text: text, isCollapsed: false), to: parent)
        }

        return document
    }

    static let input1 = """
        1
         a
          x
          y
         b
        2
        3
        """

    func testParse() {
        let doc = parse(Self.input1)
        let list = doc.visibleNodes()
        XCTAssertEqual(list.map(\.level), [0, 1, 2, 2, 1, 0, 0])
        XCTAssertEqual(list.map(\.props.text), ["1", "a", "x", "y", "b", "2", "3"])

        for id in doc.nodes.keys {
            doc.checkAncestor(forNodeWihtID: id)
        }
    }

    func testAppendAfter() {
        var doc = parse(Self.input1)
        doc.append(.init(text: "z"), after: doc.id(of: "y")!)
        let list = doc.visibleNodes()

        XCTAssertEqual(list.map(\.level), [0, 1, 2, 2, 2, 1, 0, 0])
        XCTAssertEqual(list.map(\.props.text), ["1", "a", "x", "y", "z", "b", "2", "3"])
        doc.checkAncestor(forNodeWihtID: doc.id(of: "z")!)
    }

    func testIncreaseLevel() {
        let doc = parse(Self.input1)
        XCTAssert(!doc.canIncreaseLevel(nodeID: doc.id(of: "1")!))
        XCTAssert(!doc.canIncreaseLevel(nodeID: doc.id(of: "a")!))
        XCTAssert(!doc.canIncreaseLevel(nodeID: doc.id(of: "x")!))

        var doc1 = doc
        doc1.increaseLevel(nodeID: doc.id(of: "y")!)
        let xs1 = doc1.visibleNodes()
        XCTAssertEqual(xs1.map(\.level), [0, 1, 2, 3, 1, 0, 0])
        doc1.checkAncestor(forNodeWihtID: doc.id(of: "y")!)

        var doc2 = doc
        doc2.append(.init(text: "x"), to: doc.id(of: "b")!)
        doc2.increaseLevel(nodeID: doc.id(of: "b")!)
        let xs2 = doc2.visibleNodes()
        XCTAssertEqual(xs2.map(\.level), [0, 1, 2, 2, 2, 3, 0, 0])
        doc2.checkAncestor(forNodeWihtID: doc.id(of: "a")!)

        var doc3 = doc
        doc3.increaseLevel(nodeID: doc.id(of: "2")!)
        doc3.checkAncestor(forNodeWihtID: doc.id(of: "2")!)
    }

    func testDecreaseLevel() {
        var doc = parse(Self.input1)
        XCTAssert(!doc.canDecreaseLevel(nodeID: doc.id(of: "1")!))
        XCTAssert(!doc.canDecreaseLevel(nodeID: doc.id(of: "2")!))
        XCTAssert(!doc.canDecreaseLevel(nodeID: doc.id(of: "3")!))

        doc.append(.init(text: "z"), after: doc.id(of: "y")!)
        doc.checkAncestor(forNodeWihtID: doc.id(of: "z")!)

        var doc1 = doc
        doc1.decreaseLevel(nodeID: doc.id(of: "y")!)
        let xs1 = doc1.visibleNodes()
        XCTAssertEqual(xs1.map(\.level), [0, 1, 2, 1, 2, 1, 0, 0])
        doc1.checkAncestor(forNodeWihtID: doc.id(of: "y")!)
    }

    func testCollapsing() {
        var doc = parse(Self.input1)

        doc.collapse(nodeWithID: doc.id(of: "a")!)
        XCTAssertEqual(doc.visibleNodes().map(\.props.text), ["1", "a", "b", "2", "3"])

        doc.expand(nodeWithID: doc.id(of: "a")!)
        XCTAssertEqual(doc.visibleNodes().map(\.props.text), ["1", "a", "x", "y", "b", "2", "3"])

        doc.collapse(nodeWithID: doc.id(of: "1")!)
        XCTAssertEqual(doc.visibleNodes().map(\.props.text), ["1", "2", "3"])
    }
}
