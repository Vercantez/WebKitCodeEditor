//
//  ViewController.swift
//  WebTextEditorTest
//
//  Created by Mikey Salinas on 12/27/17.
//  Copyright © 2017 Miguel Salinas. All rights reserved.
//

import UIKit
import Foundation
import WebKit

class ViewController: UIViewController, UIScrollViewDelegate {

    var codeEditorView: WKWebView!

    
    // MARK: View Lifetime
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initCodeEditor()
    }
    
    override func viewDidLayoutSubviews() {
        codeEditorView.frame = view.frame
    }
    
    func initCodeEditor() {
        
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
        
        let toolbarView = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 20))
        toolbarView.backgroundColor = .green
        
        codeEditorView = WKWebView(frame: .zero, configuration: configuration)
        codeEditorView.addRichEditorInputAccessoryView(toolbar: toolbarView)
        codeEditorView.frame = view.frame
        codeEditorView.backgroundColor = .clear
        
        // TODO: Add this back in
//        ["textDidChange"].forEach {
//            configuration.userContentController.add(WeakScriptMessageHandler(delegate: self), name: $0)
//        }
        
        codeEditorView.isOpaque = false
        codeEditorView.backgroundColor = .clear
        codeEditorView.scrollView.delegate = self
        codeEditorView.scrollView.isScrollEnabled = true
        codeEditorView.scrollView.showsHorizontalScrollIndicator = false
        codeEditorView.scrollView.showsVerticalScrollIndicator = true
        codeEditorView.scrollView.bounces = true

        view.addSubview(codeEditorView)
        codeEditorView.loadHTMLString(html, baseURL: Bundle.main.bundleURL)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return nil
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}


public class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var delegate: WKScriptMessageHandler?
    
    init(delegate: WKScriptMessageHandler) {
        self.delegate = delegate
    }
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        self.delegate?.userContentController(userContentController, didReceive: message)
    }
}

fileprivate var ToolbarHandle: UInt8 = 0

extension WKWebView {
    
    func addRichEditorInputAccessoryView(toolbar: UIView?) {
        guard let toolbar = toolbar else { return }
        objc_setAssociatedObject(self, &ToolbarHandle, toolbar, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        var candidateView: UIView? = nil
        for view in self.scrollView.subviews {
            if NSStringFromClass(type(of: view)).hasPrefix("WKContent") {
                candidateView = view
            }
        }
        guard let targetView = candidateView else { return }
        let newClass: AnyClass? = classWithCustomAccessoryView(targetView)
        object_setClass(targetView, newClass!)
    }
    
    private func classWithCustomAccessoryView(_ targetView: UIView) -> AnyClass? {
        guard let targetSuperClass = targetView.superclass else { return nil }
        let customInputAccessoryViewClassName = "\(targetSuperClass)_CustomInputAccessoryView"
        
        var newClass: AnyClass? = NSClassFromString(customInputAccessoryViewClassName)
        if newClass == nil {
            newClass = objc_allocateClassPair(object_getClass(targetView), customInputAccessoryViewClassName, 0)
        }
        else {
            return newClass
        }
        
        let newMethod = class_getInstanceMethod(WKWebView.self, #selector(WKWebView.getCustomInputAccessoryView))
        class_addMethod(newClass.self, Selector("inputAccessoryView"), method_getImplementation(newMethod!), method_getTypeEncoding(newMethod!))
        objc_registerClassPair(newClass!)
        
        return newClass
    }
    
    @objc func getCustomInputAccessoryView() -> UIView? {
        var superWebView: UIView? = self
        while (superWebView != nil) && !(superWebView is WKWebView) {
            superWebView = superWebView?.superview
        }
        let customInputAccessory = objc_getAssociatedObject(superWebView, &ToolbarHandle)
        return customInputAccessory as? UIView
    }
}
