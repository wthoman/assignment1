import SwiftData
import SwiftUI

@main
struct DaybookApp: App {
    private let container: ModelContainer
    @State private var model: AppModel

    init() {
        AppearanceConfigurator.apply()
        let container = PersistenceController.makeContainer()
        self.container = container
        _model = State(initialValue: AppModel(context: container.mainContext))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
        }
        .modelContainer(container)
    }
}

/// Creates the SwiftData container. If the on-disk store can't be opened (for example after an
/// incompatible schema change during development) it is reset, and as a last resort the app
/// runs in memory rather than crashing.
enum PersistenceController {
    static func makeContainer(inMemory: Bool = false) -> ModelContainer {
        let schema = Schema(ModelSchema.models)
        let configuration = ModelConfiguration("Daybook", schema: schema, isStoredInMemoryOnly: inMemory)
        if let container = try? ModelContainer(for: schema, configurations: [configuration]) {
            return container
        }
        // Remove the incompatible store and try once more.
        let storeURL = configuration.url
        for suffix in ["", "-shm", "-wal"] {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: storeURL.path + suffix))
        }
        if let container = try? ModelContainer(for: schema, configurations: [configuration]) {
            return container
        }
        let memory = ModelConfiguration("DaybookMemory", schema: schema, isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: schema, configurations: [memory])
        } catch {
            fatalError("SwiftData could not create even an in-memory store: \(error)")
        }
    }
}
