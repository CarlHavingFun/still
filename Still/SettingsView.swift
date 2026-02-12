import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var shareItem: ShareItem?
    @State private var showDeleteConfirm = false
    @State private var showImporter = false
    @State private var importResultMessage = ""
    @State private var showImportResult = false
    @State private var showPhilosophy = false
    @AppStorage("still.language") private var languageRaw: String = AppLanguage.defaultRawValue

    var body: some View {
        ZStack {
            PaperBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    languageSection
                    proactivitySection
                    ownershipSection
                    philosophySection
                    boundariesSection
                }
                .padding(24)
            }
        }
        .sheet(item: $shareItem) { item in
            ShareSheet(activityItems: [item.url])
        }
        .sheet(isPresented: $showPhilosophy) {
            PhilosophyDetailView(language: currentLanguage)
        }
        .confirmationDialog(deleteConfirmTitle, isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button(deleteEverythingTitle, role: .destructive) {
                appState.deleteAll()
            }
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let selectedURL = urls.first else { return }
                let hasImported = importFromSelectedURL(selectedURL)
                importResultMessage = hasImported ? importSuccessText : importFailureText
                showImportResult = true
            case .failure:
                importResultMessage = importCancelledText
                showImportResult = true
            }
        }
        .alert(importAlertTitle, isPresented: $showImportResult) {
            Button(okText, role: .cancel) {}
        } message: {
            Text(importResultMessage)
        }
    }

    private var currentLanguage: AppLanguage {
        AppLanguage.resolve(languageRaw)
    }

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(currentLanguage == .chinese ? "语言" : "Language")
                .foregroundColor(Theme.muted)

            Picker("", selection: $languageRaw) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.label).tag(language.rawValue)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.4))
        )
    }

    private var proactivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(proactiveMessagesTitle, isOn: Binding(
                get: { appState.proactivityState.enabled },
                set: { appState.setProactivityEnabled($0) }
            ))
            .tint(Theme.accent)
            .accessibilityIdentifier("settingsProactivityToggle")

            VStack(alignment: .leading, spacing: 8) {
                Text(quietHoursTitle)
                    .foregroundColor(Theme.muted)

                HStack(spacing: 16) {
                    DatePicker("", selection: Binding(
                        get: { dateFromMinutes(appState.proactivityState.quietStartMinutes) },
                        set: { appState.setQuietHours(startMinutes: minutesFromDate($0), endMinutes: appState.proactivityState.quietEndMinutes) }
                    ), displayedComponents: .hourAndMinute)
                    .labelsHidden()

                    DatePicker("", selection: Binding(
                        get: { dateFromMinutes(appState.proactivityState.quietEndMinutes) },
                        set: { appState.setQuietHours(startMinutes: appState.proactivityState.quietStartMinutes, endMinutes: minutesFromDate($0)) }
                    ), displayedComponents: .hourAndMinute)
                    .labelsHidden()
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.4))
        )
    }

    private var ownershipSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button {
                if let url = appState.exportSnapshot() {
                    shareItem = ShareItem(url: url)
                }
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exportTitle)
                        .foregroundColor(Theme.text)
                    Text(exportSubtitle)
                        .foregroundColor(Theme.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            Button {
                showImporter = true
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(importTitle)
                        .foregroundColor(Theme.text)
                    Text(importSubtitle)
                        .foregroundColor(Theme.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(deleteEverythingTitle)
                        .foregroundColor(Theme.text)
                    Text(deleteSubtitle)
                        .foregroundColor(Theme.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.4))
        )
    }

    private var boundariesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(boundaryLines, id: \.self) { line in
                Text(line)
            }
        }
        .foregroundColor(Theme.text)
        .lineSpacing(6)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.4))
        )
    }

    private var philosophySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button {
                showPhilosophy = true
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(philosophyTitle)
                        .foregroundColor(Theme.text)
                    Text(philosophySubtitle)
                        .foregroundColor(Theme.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.4))
        )
    }

    private var proactiveMessagesTitle: String {
        currentLanguage == .chinese ? "主动消息" : "Proactive messages"
    }

    private var quietHoursTitle: String {
        currentLanguage == .chinese ? "静默时段" : "Quiet hours"
    }

    private var exportTitle: String {
        currentLanguage == .chinese ? "导出全部内容" : "Export everything"
    }

    private var exportSubtitle: String {
        currentLanguage == .chinese ? "把所有数据带走。" : "Take everything with you."
    }

    private var importTitle: String {
        currentLanguage == .chinese ? "导入记忆" : "Import memory"
    }

    private var importSubtitle: String {
        currentLanguage == .chinese ? "从导出的 JSON 恢复。" : "Restore from exported JSON."
    }

    private var deleteEverythingTitle: String {
        currentLanguage == .chinese ? "删除全部内容" : "Delete everything"
    }

    private var deleteSubtitle: String {
        currentLanguage == .chinese ? "删除本机全部本地数据。" : "Remove all local data from this device."
    }

    private var deleteConfirmTitle: String {
        currentLanguage == .chinese ? "从这台设备删除全部本地数据。" : "Remove all local data from this device."
    }

    private var importAlertTitle: String {
        currentLanguage == .chinese ? "导入" : "Import"
    }

    private var importSuccessText: String {
        currentLanguage == .chinese ? "导入成功。" : "Import succeeded."
    }

    private var importFailureText: String {
        currentLanguage == .chinese ? "导入失败，格式无效。" : "Import failed. Invalid format."
    }

    private var importCancelledText: String {
        currentLanguage == .chinese ? "导入取消或失败。" : "Import cancelled or failed."
    }

    private var okText: String {
        currentLanguage == .chinese ? "好的" : "OK"
    }

    private var boundaryLines: [String] {
        if currentLanguage == .chinese {
            return [
                "Still 不分析你。",
                "Still 不定义你。",
                "Still 不催促你。",
                "未完成可以存在。",
                "离开也可以。"
            ]
        }
        return [
            "Still does not analyze you.",
            "Still does not define you.",
            "Still does not rush you.",
            "Unfinished is allowed.",
            "Leaving is allowed."
        ]
    }

    private var philosophyTitle: String {
        currentLanguage == .chinese ? "设计哲学（详细）" : "Design Philosophy (Detailed)"
    }

    private var philosophySubtitle: String {
        currentLanguage == .chinese ? "按页查看 AGENTS、PRD、DESIGN、SCHEMA、COPY 的完整边界。" : "Read AGENTS, PRD, DESIGN, SCHEMA, and COPY boundaries page by page."
    }

    private func dateFromMinutes(_ minutes: Int) -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .minute, value: minutes, to: today) ?? today
    }

    private func minutesFromDate(_ date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        return hour * 60 + minute
    }

    private func importFromSelectedURL(_ url: URL) -> Bool {
        let hasAccess = url.startAccessingSecurityScopedResource()
        defer {
            if hasAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        return appState.importSnapshot(from: url)
    }
}

private struct ShareItem: Identifiable {
    let id = UUID()
    let url: URL
}

private struct PhilosophyDetailView: View {
    let language: AppLanguage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            TabView {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(page.title)
                                .font(.system(size: 24, weight: .regular))
                                .foregroundColor(Theme.text)
                            ForEach(page.lines, id: \.self) { line in
                                Text(line)
                                    .font(.system(size: 16))
                                    .foregroundColor(Theme.text)
                                    .lineSpacing(5)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(24)
                    }
                    .background(Theme.background)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .background(Theme.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(Theme.muted)
                    }
                    .accessibilityLabel(language == .chinese ? "关闭" : "Close")
                }
            }
        }
    }

    private var pages: [PhilosophyPage] {
        switch language {
        case .chinese:
            return chinesePages
        case .english:
            return englishPages
        }
    }

    private var englishPages: [PhilosophyPage] {
        [
            PhilosophyPage(
                title: "1. Core Identity",
                lines: [
                    "Still is not a chatbot, therapist, coach, journal, or insight engine.",
                    "Still exists to hold continuity.",
                    "Pausing is valid. Stopping is valid. Leaving is valid.",
                    "Still remembers position, not interpretation."
                ]
            ),
            PhilosophyPage(
                title: "2. Relationship Boundaries",
                lines: [
                    "Still does not lead and does not follow.",
                    "Still stays where the user last stopped.",
                    "Still remembers hesitation, not conclusions.",
                    "Silence is kept as silence."
                ]
            ),
            PhilosophyPage(
                title: "3. Hard Prohibitions",
                lines: [
                    "Never diagnose, label, or analyze the user.",
                    "Never define who the user is.",
                    "Never generate insights or summaries about the user.",
                    "Never use streaks, stats, rewards, or gamification.",
                    "Never merge user inputs into one growing document."
                ]
            ),
            PhilosophyPage(
                title: "4. Memory Model",
                lines: [
                    "Memory exists to prevent disappearance, not to create identity.",
                    "Kept: explicit or repeatedly confirmed facts only.",
                    "Held: unfinished pause-points. Never auto-promoted.",
                    "Passing: temporary and expires unless confirmed.",
                    "If unsure, do not store as fact."
                ]
            ),
            PhilosophyPage(
                title: "5. Proactivity Rules",
                lines: [
                    "Still speaks first only to signal continuity.",
                    "Never to demand attention or fill silence.",
                    "At most one proactive message per day.",
                    "Quiet hours are respected.",
                    "Ignoring Still makes it quieter, not louder."
                ]
            ),
            PhilosophyPage(
                title: "6. Product Scope (PRD)",
                lines: [
                    "One input equals one event.",
                    "Events are not merged into articles or chapters.",
                    "Home has one writing area and no feed.",
                    "Memory is grouped by state, not by growth narrative.",
                    "User can export, edit, and delete everything."
                ]
            ),
            PhilosophyPage(
                title: "7. Design and Language",
                lines: [
                    "Visual language stays calm and low pressure.",
                    "No chat bubbles, avatars, typing indicators, or completion pressure.",
                    "Copy stays short, plain, and non-urgent.",
                    "Unfinished is allowed. Leaving is allowed.",
                    "Still holds position, not meaning."
                ]
            )
        ]
    }

    private var chinesePages: [PhilosophyPage] {
        [
            PhilosophyPage(
                title: "1. 核心身份",
                lines: [
                    "Still 不是聊天机器人、治疗师、教练、日记或洞察引擎。",
                    "Still 的存在是为了承接连续性。",
                    "暂停是有效的。停下是有效的。离开是有效的。",
                    "Still 记住的是位置，不是解释。"
                ]
            ),
            PhilosophyPage(
                title: "2. 关系边界",
                lines: [
                    "Still 不带领你，也不跟随你。",
                    "Still 停在你上次停下的地方。",
                    "Still 记住犹豫，不记住结论。",
                    "沉默就是沉默，不被解释。"
                ]
            ),
            PhilosophyPage(
                title: "3. 严格禁止",
                lines: [
                    "禁止诊断、贴标签、分析用户。",
                    "禁止定义用户是谁。",
                    "禁止产出关于用户的总结或洞察。",
                    "禁止打卡、统计、奖励和游戏化机制。",
                    "禁止把多次输入合并成持续增长的一篇文档。"
                ]
            ),
            PhilosophyPage(
                title: "4. 记忆模型",
                lines: [
                    "记忆的目的：防止消失，而不是构建身份。",
                    "Kept：仅明确或反复确认的事实。",
                    "Held：未完成停留点，绝不自动升级。",
                    "Passing：临时记忆，不确认就过期。",
                    "不确定时，不作为事实存储。"
                ]
            ),
            PhilosophyPage(
                title: "5. 主动性规则",
                lines: [
                    "Still 主动开口只为提示连续性。",
                    "不会索取注意，不会填补沉默。",
                    "每天最多一条主动消息。",
                    "必须遵守静默时段。",
                    "被忽略时应更安静，而不是更频繁。"
                ]
            ),
            PhilosophyPage(
                title: "6. 产品范围（PRD）",
                lines: [
                    "一次输入就是一个事件。",
                    "事件不会被合并成章节或文章。",
                    "主页只有书写区域，没有信息流。",
                    "记忆按状态组织，而不是按成长叙事组织。",
                    "用户可以导出、编辑、删除全部数据。"
                ]
            ),
            PhilosophyPage(
                title: "7. 设计与文案",
                lines: [
                    "视觉语言保持平静、低压。",
                    "不使用聊天气泡、头像、输入中提示、完成压力。",
                    "文案短句、平实、无催促。",
                    "允许未完成。允许离开。",
                    "Still 承接位置，不解释意义。"
                ]
            )
        ]
    }
}

private struct PhilosophyPage {
    let title: String
    let lines: [String]
}
