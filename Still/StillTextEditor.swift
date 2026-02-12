import SwiftUI
import UIKit

struct StillTextEditor: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool
    var fadeTrigger: Int = 0
    var onFadeOutComplete: (() -> Void)? = nil

    var ghostText: String
    var ghostDelay: TimeInterval = 1.5
    var ghostFadeDuration: TimeInterval = 4.0

    func makeUIView(context: Context) -> StillTextView {
        let textView = StillTextView()
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        textView.textContainer.lineFragmentPadding = 0
        textView.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        textView.textColor = UIColor(Theme.text)
        textView.tintColor = UIColor(Theme.accent)
        textView.textAlignment = .natural
        textView.alwaysBounceVertical = false
        textView.ghostText = ghostText
        textView.ghostDelay = ghostDelay
        textView.ghostFadeDuration = ghostFadeDuration
        textView.syncGhostFont()
        textView.setGhostVisibility(isVisible: text.isEmpty)
        textView.alignContentIfNeeded()
        return textView
    }

    func updateUIView(_ uiView: StillTextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
            uiView.alignContentIfNeeded()
        }
        uiView.ghostText = ghostText
        uiView.ghostDelay = ghostDelay
        uiView.ghostFadeDuration = ghostFadeDuration
        uiView.syncGhostFont()
        uiView.setGhostVisibility(isVisible: text.isEmpty)

        if isFocused && !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        } else if !isFocused && uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
        uiView.updateCaretLayer()

        if context.coordinator.lastFadeTrigger != fadeTrigger {
            context.coordinator.lastFadeTrigger = fadeTrigger
            uiView.fadeOutAndClear {
                onFadeOutComplete?()
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        private let parent: StillTextEditor
        fileprivate var lastFadeTrigger: Int

        init(_ parent: StillTextEditor) {
            self.parent = parent
            self.lastFadeTrigger = parent.fadeTrigger
        }

        func textViewDidChange(_ textView: UITextView) {
            guard let stillView = textView as? StillTextView else { return }
            parent.text = stillView.text
            stillView.setGhostVisibility(isVisible: stillView.text.isEmpty)
            stillView.alignContentIfNeeded()
            stillView.updateCaretLayer()
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            (textView as? StillTextView)?.updateCaretLayer()
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            parent.isFocused = true
            (textView as? StillTextView)?.updateCaretLayer()
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            parent.isFocused = false
        }
    }
}

final class StillTextView: UITextView {
    private let ghostLabel = UILabel()
    private let caretLayer = CALayer()
    private var ghostWorkItem: DispatchWorkItem?

    var ghostText: String = "" {
        didSet { ghostLabel.text = ghostText }
    }

    var ghostDelay: TimeInterval = 1.5
    var ghostFadeDuration: TimeInterval = 4.0

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    override func caretRect(for position: UITextPosition) -> CGRect {
        return .zero
    }

    private func configure() {
        ghostLabel.numberOfLines = 0
        ghostLabel.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        ghostLabel.textColor = UIColor(Theme.muted).withAlphaComponent(0.8)
        ghostLabel.alpha = 0
        addSubview(ghostLabel)

        caretLayer.backgroundColor = UIColor(Theme.accent).withAlphaComponent(0.5).cgColor
        caretLayer.cornerRadius = 1
        layer.addSublayer(caretLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        alignContentIfNeeded()
        layoutGhostLabel()
        updateCaretLayer()
    }

    func syncGhostFont() {
        ghostLabel.font = font ?? UIFont.systemFont(ofSize: 18, weight: .regular)
        setNeedsLayout()
    }

    func alignContentIfNeeded() {
        let expectedY = -adjustedContentInset.top
        let availableHeight = bounds.height - textContainerInset.top - textContainerInset.bottom
        guard contentSize.height <= availableHeight else { return }
        if abs(contentOffset.y - expectedY) > 0.5 {
            setContentOffset(CGPoint(x: contentOffset.x, y: expectedY), animated: false)
        }
    }

    func setGhostVisibility(isVisible: Bool) {
        ghostWorkItem?.cancel()
        ghostWorkItem = nil

        if isVisible {
            ghostLabel.alpha = 1
            ghostLabel.isHidden = false
        } else {
            ghostLabel.alpha = 0
            ghostLabel.isHidden = true
        }
    }

    func fadeOutAndClear(completion: @escaping () -> Void) {
        guard !text.isEmpty else {
            completion()
            return
        }
        isUserInteractionEnabled = false
        UIView.animate(withDuration: 1.8, delay: 0, options: [.curveEaseOut]) {
            self.alpha = 0
        } completion: { _ in
            self.text = ""
            self.alpha = 1
            self.isUserInteractionEnabled = true
            self.setGhostVisibility(isVisible: true)
            self.updateCaretLayer()
            completion()
        }
    }

    func updateCaretLayer() {
        guard let selection = selectedTextRange else { return }
        let rect = super.caretRect(for: selection.end)
        let height = max(16, rect.height)
        let width: CGFloat = 2
        let x = rect.origin.x
        let y = rect.origin.y + (rect.height - height) / 2
        caretLayer.frame = CGRect(x: x, y: y, width: width, height: height)
        caretLayer.isHidden = !isFirstResponder
    }

    private func layoutGhostLabel() {
        let inset = textContainerInset
        let padding = textContainer.lineFragmentPadding
        let maxWidth = bounds.width - inset.left - inset.right - padding * 2
        let size = ghostLabel.sizeThatFits(CGSize(width: maxWidth, height: .greatestFiniteMagnitude))
        ghostLabel.frame = CGRect(x: inset.left + padding, y: inset.top, width: maxWidth, height: size.height)
    }
}
