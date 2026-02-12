import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @State private var inputText: String = ""
    @AppStorage("still.hasLaunched") private var hasLaunched: Bool = false
    @State private var showFirstRun = false
    @State private var isFocused = false
    @State private var fadeTrigger = 0
    @State private var isAutoFading = false
    @State private var idleWorkItem: DispatchWorkItem?
    @State private var rememberHintOpacity: Double = 0
    @State private var rememberHintWorkItem: DispatchWorkItem?
    @AppStorage("still.language") private var languageRaw: String = AppLanguage.defaultRawValue

    var body: some View {
        ZStack {
            PaperBackground()

            VStack(alignment: .leading, spacing: 24) {
                Text(homeTitle)
                    .font(.system(size: 28, weight: .regular))
                    .foregroundColor(Theme.text)
                    .accessibilityIdentifier("homeTitle")

                ZStack(alignment: .bottomTrailing) {
                    StillTextEditor(
                        text: $inputText,
                        isFocused: $isFocused,
                        fadeTrigger: fadeTrigger,
                        onFadeOutComplete: handleFadeComplete,
                        ghostText: ghostText
                    )
                    .frame(minHeight: 240)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.4))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Theme.subtle, lineWidth: 1)
                    )
                    .accessibilityIdentifier("homeInput")

                    HStack(spacing: 8) {
                        Button(action: submit) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(Theme.accent)
                                .padding(12)
                        }
                        .opacity(canSubmit ? 1 : 0.3)
                        .disabled(!canSubmit)
                        .accessibilityIdentifier("homeSubmit")
                    }
                }

                Spacer()
            }
            .padding(24)

            VStack {
                Spacer()
                Text(rememberHintText)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.muted)
                    .lineSpacing(4)
                    .opacity(rememberHintOpacity)
                    .padding(.bottom, 12)
                    .accessibilityIdentifier("homeRememberHint")
            }
            .padding(.horizontal, 24)
            .allowsHitTesting(false)
        }
        .contentShape(Rectangle())
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onTapGesture {
            isFocused = false
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button {
                    isFocused = false
                } label: {
                    Image(systemName: "keyboard.chevron.compact.down")
                        .foregroundColor(Theme.muted)
                }
            }
        }
        .onAppear {
            if AppLanguage(rawValue: languageRaw) == nil {
                languageRaw = AppLanguage.defaultRawValue
            }
            showFirstRun = !hasLaunched
        }
        .onDisappear {
            rememberHintWorkItem?.cancel()
            rememberHintWorkItem = nil
        }
        .sheet(isPresented: $showFirstRun) {
            FirstRunView {
                hasLaunched = true
                showFirstRun = false
            }
            .interactiveDismissDisabled()
        }
        .onChange(of: inputText, initial: false) { _, _ in
            scheduleAutoCommit()
        }
    }

    private var canSubmit: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func submit() {
        idleWorkItem?.cancel()
        idleWorkItem = nil
        isAutoFading = false
        appState.addInput(inputText)
        showRememberHint()
        inputText = ""
    }

    private var currentLanguage: AppLanguage {
        AppLanguage.resolve(languageRaw)
    }

    private var homeTitle: String {
        "Still here."
    }

    private var ghostText: String {
        ""
    }

    private var rememberHintText: String {
        switch currentLanguage {
        case .english:
            return "I remember."
        case .chinese:
            return "我记住了。"
        }
    }

    private func scheduleAutoCommit() {
        idleWorkItem?.cancel()
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let work = DispatchWorkItem { [text = inputText] in
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            autoCommit(text: trimmed)
        }
        idleWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: work)
    }

    private func autoCommit(text: String) {
        guard !isAutoFading else { return }
        isAutoFading = true
        appState.addInput(text)
        showRememberHint()
        fadeTrigger += 1
    }

    private func handleFadeComplete() {
        inputText = ""
        isAutoFading = false
    }

    private func showRememberHint() {
        rememberHintWorkItem?.cancel()
        rememberHintOpacity = 1

        let work = DispatchWorkItem {
            withAnimation(.easeOut(duration: 1.6)) {
                rememberHintOpacity = 0
            }
        }
        rememberHintWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: work)
    }
}

private struct FirstRunView: View {
    let onDismiss: () -> Void
    @AppStorage("still.language") private var languageRaw: String = AppLanguage.defaultRawValue

    var body: some View {
        ZStack {
            Theme.background
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                Text(firstRunLines[0])
                    .font(.system(size: 20))
                    .foregroundColor(Theme.text)
                    .lineSpacing(6)

                Text(firstRunLines[1])
                    .font(.system(size: 18))
                    .foregroundColor(Theme.text)
                    .lineSpacing(6)

                Text(firstRunLines[2])
                    .font(.system(size: 18))
                    .foregroundColor(Theme.text)
                    .lineSpacing(6)

                Text(firstRunLines[3])
                    .font(.system(size: 18))
                    .foregroundColor(Theme.text)
                    .lineSpacing(6)

                Spacer()
            }
            .padding(28)

            VStack {
                HStack {
                    Picker("", selection: $languageRaw) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.label).tag(language.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 132)
                    .accessibilityIdentifier("firstRunLanguage")

                    Spacer()

                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Theme.muted)
                            .padding(12)
                    }
                    .accessibilityLabel(currentLanguage == .chinese ? "关闭" : "Close")
                    .accessibilityIdentifier("firstRunClose")
                }
                Spacer()
            }
            .padding(16)
        }
    }

    private var currentLanguage: AppLanguage {
        AppLanguage.resolve(languageRaw)
    }

    private var firstRunLines: [String] {
        switch currentLanguage {
        case .english:
            return [
                "You're here. We can start anywhere.",
                "We don't have to do anything.\nYou can just put something down here.",
                "I'm going to keep this.\nNot to explain it - just to remember where you stopped.",
                "You don't owe me anything.\nYou can leave and come back whenever you want.\nI'll keep the place."
            ]
        case .chinese:
            return [
                "你在这里。我们可以从任何地方开始。",
                "我们不必做任何事。\n你可以把一些东西放在这里。",
                "我会把它留下。\n不是为了解释——只是记住你停下的地方。",
                "你不欠我什么。\n你可以离开，也可以回来。\n我会守在这里。"
            ]
        }
    }
}
