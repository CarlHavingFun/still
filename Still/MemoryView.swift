import SwiftUI

struct MemoryView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedItem: MemoryItem?
    @State private var expandedCategories: Set<MemoryCategory> = []
    @AppStorage("still.language") private var languageRaw: String = AppLanguage.defaultRawValue

    private let collapsedLimit = 24

    var body: some View {
        ZStack {
            PaperBackground()

            List {
                memorySection(category: .kept, items: appState.keptItems)
                memorySection(category: .held, items: appState.heldItems)
                memorySection(category: .passing, items: appState.passingItems)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .sheet(item: $selectedItem) { item in
            MemoryEditView(item: item) { updatedBody, updatedCategory in
                appState.updateMemoryItem(item, body: updatedBody, category: updatedCategory)
            }
        }
    }

    private var currentLanguage: AppLanguage {
        AppLanguage.resolve(languageRaw)
    }

    private func memorySection(category: MemoryCategory, items: [MemoryItem]) -> some View {
        let visibleItems = displayedItems(for: category, items: items)

        return Section(
            header: Text(category.title(for: currentLanguage))
                .foregroundColor(Theme.muted)
                .font(.system(size: 14, weight: .semibold))
                .accessibilityIdentifier("memorySection\(category.rawValue)")
        ) {
            if items.isEmpty {
                Text(currentLanguage == .chinese ? "这里还没有内容。" : "Nothing here yet.")
                    .foregroundColor(Theme.muted.opacity(0.9))
                    .font(.system(size: 13))
                    .padding(.vertical, 8)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(visibleItems) { item in
                    row(for: item)
                }

                if items.count > collapsedLimit {
                    Button {
                        toggleExpansion(for: category)
                    } label: {
                        Text(expandedCategories.contains(category) ? collapseLabel : showMoreLabel)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Theme.accent)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.clear)
                }
            }
        }
    }

    private func row(for item: MemoryItem) -> some View {
        return VStack(alignment: .leading, spacing: 8) {
            Button {
                selectedItem = item
            } label: {
                Text(item.body)
                    .foregroundColor(Theme.text)
                    .lineSpacing(6)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 10)
        .listRowBackground(Color.clear)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                appState.deleteMemoryItem(item)
            } label: {
                Image(systemName: "trash")
            }
        }
    }

    private func displayedItems(for category: MemoryCategory, items: [MemoryItem]) -> [MemoryItem] {
        if expandedCategories.contains(category) || items.count <= collapsedLimit {
            return items
        }
        return Array(items.prefix(collapsedLimit))
    }

    private func toggleExpansion(for category: MemoryCategory) {
        if expandedCategories.contains(category) {
            expandedCategories.remove(category)
        } else {
            expandedCategories.insert(category)
        }
    }

    private var showMoreLabel: String {
        currentLanguage == .chinese ? "继续显示" : "Show more"
    }

    private var collapseLabel: String {
        currentLanguage == .chinese ? "收起" : "Collapse"
    }
}

private struct MemoryEditView: View {
    let item: MemoryItem
    let onSave: (String, MemoryCategory) -> Void

    @Environment(\.dismiss) private var dismiss
    @AppStorage("still.language") private var languageRaw: String = AppLanguage.defaultRawValue
    @State private var bodyText: String
    @State private var category: MemoryCategory

    init(item: MemoryItem, onSave: @escaping (String, MemoryCategory) -> Void) {
        self.item = item
        self.onSave = onSave
        _bodyText = State(initialValue: item.body)
        _category = State(initialValue: item.category)
    }

    var body: some View {
        ZStack {
            Theme.background
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                Picker("", selection: $category) {
                    ForEach(MemoryCategory.allCases) { category in
                        Text(category.title(for: currentLanguage)).tag(category)
                    }
                }
                .pickerStyle(.segmented)

                TextEditor(text: $bodyText)
                    .font(.system(size: 18))
                    .foregroundColor(Theme.text)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Theme.subtle, lineWidth: 1)
                    )

                Spacer()
            }
            .padding(24)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: save) {
                    Image(systemName: "checkmark")
                }
                .foregroundColor(Theme.accent)
            }
        }
    }

    private var currentLanguage: AppLanguage {
        AppLanguage.resolve(languageRaw)
    }

    private func save() {
        let trimmed = bodyText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onSave(trimmed, category)
        dismiss()
    }
}
