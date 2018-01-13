import Foundation
import WebKit

public protocol RichTextEditorDelegate: class {
    func textDidChange(text: String)
    func heightDidChange()
}

public class RichTextEditor: UIView, WKScriptMessageHandler, WKNavigationDelegate, UIScrollViewDelegate {

    private static let textDidChange = "textDidChange"
    private static let heightDidChange = "heightDidChange"
    private static let defaultHeight: CGFloat = 60

    public weak var delegate: RichTextEditorDelegate?
    public var height: CGFloat = RichTextEditor.defaultHeight

    private var textToLoad: String?
    public var text: String? {
        didSet {
            guard let text = text else { return }
            if editorView.isLoading {
                textToLoad = text
            }
        }
    }

    private var editorView: WKWebView!

    public override init(frame: CGRect = .zero) {
        
        let bundlePath = Bundle.main.bundlePath
        guard let bundle = Bundle(path: bundlePath),
            let scriptPath = bundle.path(forResource: "RichTextEditor", ofType: "js"),
            let scriptContent = try? String(contentsOfFile: scriptPath, encoding: String.Encoding.utf8),
            let htmlPath = bundle.path(forResource: "RichTextEditor", ofType: "html"),
            let html = try? String(contentsOfFile: htmlPath, encoding: String.Encoding.utf8)
            else { fatalError("Unable to find javscript/html for text editor") }

        let configuration = WKWebViewConfiguration()
        let codeStringScript = WKUserScript(source: "var codeString = \"heyyy\"", injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        let script = WKUserScript(source: scriptContent, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        configuration.userContentController.addUserScript(codeStringScript)
        configuration.userContentController.addUserScript(script)

        editorView = WKWebView(frame: .zero, configuration: configuration)

        super.init(frame: frame)

        [RichTextEditor.textDidChange, RichTextEditor.heightDidChange].forEach {
            configuration.userContentController.add(WeakScriptMessageHandler(delegate: self), name: $0)
        }

        editorView.navigationDelegate = self
        editorView.isOpaque = false
        editorView.backgroundColor = .clear
        editorView.scrollView.isScrollEnabled = true
        editorView.scrollView.showsHorizontalScrollIndicator = false
        editorView.scrollView.showsVerticalScrollIndicator = true
        editorView.scrollView.bounces = true
        editorView.scrollView.delegate = self

        addSubview(editorView)
        editorView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            editorView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            editorView.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            editorView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            editorView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        editorView.loadHTMLString(html, baseURL: Bundle.main.bundleURL)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case RichTextEditor.textDidChange:
            guard let body = message.body as? String else { return }
            delegate?.textDidChange(text: body)
        case RichTextEditor.heightDidChange:
            
            guard let height = message.body as? CGFloat else { return }
            
            self.height = height > RichTextEditor.defaultHeight ? height + 30 : RichTextEditor.defaultHeight
            delegate?.heightDidChange()
        default:
            break
        }
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let textToLoad = textToLoad {
            self.textToLoad = nil
            text = textToLoad
        }
    }

    public func viewForZooming(in: UIScrollView) -> UIView? {
        return nil
    }

}
