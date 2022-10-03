import BenoteModel
import ComposableArchitecture
import SwiftUI
import UIKit

final class NodeEditorUITextView: UITextView {
    var viewStore: ViewStoreOf<NodeEditor>!
    var documentStore: StoreOf<DocumentEditor>!

    @objc
    func increaseLevel(_ sender: Any) {
        viewStore.send(.increaseLevel)
    }

    @objc
    func decreaseLevel(_ sender: Any) {
        viewStore.send(.decreaseLevel)
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(increaseLevel(_:)) {
            return ViewStore(documentStore).state.canIncreaseLevel(nodeID: viewStore.id)
        }
        if action == #selector(decreaseLevel(_:)) {
            return ViewStore(documentStore).state.canDecreaseLevel(nodeID: viewStore.id)
        }
        return super.canPerformAction(action, withSender: sender)
    }

    override var keyCommands: [UIKeyCommand]? {
        var list = super.keyCommands ?? []
        let tab = UIKeyCommand(
            input: "\t",
            modifierFlags: [],
            action: #selector(increaseLevel(_:)))
        tab.wantsPriorityOverSystemBehavior = true
        list.append(tab)

        let shiftTab = UIKeyCommand(
            input: "\t",
            modifierFlags: [.shift],
            action: #selector(decreaseLevel(_:)))
        tab.wantsPriorityOverSystemBehavior = true
        list.append(shiftTab)
        return list
    }
}

struct NodeEditorTextView: UIViewRepresentable {
    @ObservedObject var viewStore: ViewStoreOf<NodeEditor>
    var documentStore: StoreOf<DocumentEditor>

    func makeCoordinator() -> Coordinator {
        .init(viewStore: viewStore)
    }

    func makeUIView(context: Context) -> NodeEditorUITextView {
        let textView = NodeEditorUITextView()

        textView.viewStore = viewStore
        textView.documentStore = documentStore
        textView.delegate = context.coordinator

        textView.isScrollEnabled = false
        textView.font = .systemFont(ofSize: 16)
        textView.backgroundColor = .clear

        return textView
    }

    func updateUIView(_ view: NodeEditorUITextView, context: Context) {
        if view.markedTextRange == nil, view.text != viewStore.props.text {
            view.text = viewStore.props.text
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, view: NodeEditorUITextView, context: Context) -> CGSize? {
        guard let width = proposal.width else { return nil }
        let height = view.sizeThatFits(.init(width: width, height: .infinity)).height
        return .init(width: width, height: height)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var viewStore: ViewStoreOf<NodeEditor>

        init(viewStore: ViewStoreOf<NodeEditor>) {
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
            if viewStore.props.text != textView.text {
                viewStore.send(.setText(textView.text))
            }
        }
    }
}
