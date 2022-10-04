import BenoteModel
import ComposableArchitecture
import Foundation
import OSLog

public struct AppFeature: ReducerProtocol {
    public struct State: Equatable {
        public var editor: DocumentEditor.State
    }

    public enum Action: Equatable {
        case editor(DocumentEditor.Action)
        case save(Document)
        case backup(Document)
    }

    public func reduceSelf(into state: inout State, action: Action) -> Effect<Action, Never> {
        switch action {
        case .save(let document):
            return Effect.fireAndForget {
                do {
                    try document.encode().write(to: AppFeature.jsonPath, options: [.atomic])
                } catch {
                    Logger.storage.error("An error occurred when saving data. Error: \(error.localizedDescription)")
                    fatalError("An error happened when saving data.")
                }
            }

        case .backup(let document):
            return Effect.fireAndForget {
                do {
                    try document.encode().write(to: AppFeature.currentBackupPath(), options: [.atomic])
                } catch {
                    Logger.storage.error("An error occurred when backuping data. Error: \(error.localizedDescription)")
                    fatalError("An error happened when backuping data.")
                }
            }

        default:
            return Effect.none
        }
    }

    @ReducerBuilderOf<AppFeature>
    public var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            reduceSelf(into: &state, action: action)

        }
        Scope(state: \.editor, action: CasePath(Action.editor)) {
            DocumentEditor()
        }
        .onChange(of: \.editor.document) { _, newValue in
            Effect.merge(
                Effect(value: Action.save(newValue))
                    .throttle(id: "save", for: 1, scheduler: RunLoop.main, latest: true),
                Effect(value: Action.backup(newValue))
                    .throttle(id: "backup", for: 60, scheduler: RunLoop.main, latest: false)
            )
        }
    }
}

extension AppFeature.State {
    public static let initialState: Self = {
        let document: Document
        do {
            let data = try Data(contentsOf: AppFeature.jsonPath)
            document = try Document(data: data)
        } catch {
            Logger.storage.error("An error occurred when loading data, creating a new one instead. Error: \(error.localizedDescription)")
            document = Document.initialState
        }
        return .init(editor: .init(document: document))
    }()
}

extension AppFeature {
    static let folderPath = try! FileManager.default.url(
        for: .documentDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: true)

    static let jsonPath = URL(filePath: "data.json", relativeTo: folderPath)
    static func currentBackupPath() -> URL {
        var calender = Calendar.current
        calender.timeZone = .gmt
        let ks = calender.dateComponents([.year, .month, .day, .hour, .minute], from: Date())

        let backupFolder = folderPath
            .appending(component: "backups")
            .appending(component: ks.year!.description)
            .appending(component: ks.month!.description)
            .appending(component: ks.day!.description)
        try? FileManager.default.createDirectory(at: backupFolder, withIntermediateDirectories: true)

        let filename = String(format: "%02d%02d.json", ks.hour!, ks.minute!)
        return backupFolder.appending(component: filename)
    }
}

extension Logger {
    static let storage = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "storage")
}
