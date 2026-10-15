import UIKit
import SwiftUI
import UniformTypeIdentifiers

final class ActionViewController: UIViewController {
    private var selectedText: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        extractSelectedText { [weak self] extractedWord in
            DispatchQueue.main.async {
                self?.presentSwiftUIView(initialWord: extractedWord)
            }
        }
    }

    private func extractSelectedText(completion: @escaping (String) -> Void) {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
            completion("")
            return
        }

        for item in items {
            guard let attachments = item.attachments else { continue }
            for provider in attachments {
                if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { (data, _) in
                        if let text = data as? String {
                            completion(self.cleanWord(text))
                            return
                        }
                    }
                    return
                } else if provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { (data, _) in
                        if let text = data as? String {
                            completion(self.cleanWord(text))
                            return
                        }
                    }
                    return
                }
            }
        }
        completion("")
    }

    private func cleanWord(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let firstToken = trimmed.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).first.map(String.init) ?? trimmed
        let cleaned = firstToken.trimmingCharacters(in: CharacterSet.punctuationCharacters.union(.symbols))
        return cleaned
    }

    private func presentSwiftUIView(initialWord: String) {
        let rootView = ActionLookupView(
            initialWord: initialWord,
            onClose: { [weak self] in
                self?.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            },
            onOpenInApp: { [weak self] word in
                guard let self = self else { return }
                if let url = URL(string: "kamus://search?q=\(word.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? word)") {
                    self.openURL(url)
                }
                self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            }
        )

        let hostingController = UIHostingController(rootView: rootView)
        addChild(hostingController)
        hostingController.view.frame = view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
    }

    private func openURL(_ url: URL) {
        var responder: UIResponder? = self
        while responder != nil {
            if let app = responder as? UIApplication {
                app.open(url, options: [:], completionHandler: nil)
                return
            }
            responder = responder?.next
        }
    }
}
