import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class CategoryStore {
    private let modelContext: ModelContext
    private(set) var categories: [ClipboardCategory] = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        load()
    }

    func load() {
        var descriptor = FetchDescriptor<ClipboardCategory>(
            sortBy: [SortDescriptor(\.name, order: .forward)]
        )
        descriptor.fetchLimit = 200
        categories = (try? modelContext.fetch(descriptor)) ?? []
    }

    func create(name: String, colorHex: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let category = ClipboardCategory(name: trimmed, colorHex: colorHex)
        modelContext.insert(category)
        saveAndReload()
    }

    func delete(_ category: ClipboardCategory) {
        modelContext.delete(category)
        saveAndReload()
    }

    func category(for id: UUID?) -> ClipboardCategory? {
        guard let id else { return nil }
        return categories.first { $0.id == id }
    }

    private func saveAndReload() {
        do {
            try modelContext.save()
        } catch {
            print("⚠️ Failed to save category changes: \(error.localizedDescription)")
        }
        load()
    }
}
