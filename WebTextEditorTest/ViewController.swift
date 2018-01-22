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
        
        codeEditorView = WKWebView(frame: .zero, configuration: configuration)
        codeEditorView.addCustomUndoManager()
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
    
    func addCustomUndoManager() {
        
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
        let customInputAccessoryViewClassName = "\(type(of: targetView))_Custom"
        
        var newClass: AnyClass? = NSClassFromString(customInputAccessoryViewClassName)
        if newClass == nil {
            newClass = objc_allocateClassPair(object_getClass(targetView), customInputAccessoryViewClassName, 0)
        }
        else {
            return newClass
        }

        let newUndoManager = class_getInstanceMethod(WKWebView.self, #selector(WKWebView.getCustomUndoManager))
        class_addMethod(newClass.self, Selector("undoManager"), method_getImplementation(newUndoManager!), method_getTypeEncoding(newUndoManager!))
        objc_registerClassPair(newClass!)
        
        return newClass
    }
    
    @objc func getCustomUndoManager() -> UndoManager {
        
        var superWebView: UIView? = self
        while (superWebView != nil) && !(superWebView is WKWebView) {
            superWebView = superWebView?.superview
        }
        
        let superWKWebView = superWebView as! WKWebView
        
        let undoManager = WebUndoManager()
        
        undoManager.undoAction = { superWKWebView.evaluateJavaScript("myCodeMirror.execCommand(\"undo\")") }
        undoManager.redoAction = { superWKWebView.evaluateJavaScript("myCodeMirror.execCommand(\"redo\")") }
        
        return undoManager
    }
    
}

class WebUndoManager: UndoManager {
    
    var undoAction: (() -> Void)?
    var redoAction: (() -> Void)?
    
    override var canUndo: Bool {
        return true
    }
    
    override var canRedo: Bool {
        return true
    }
    
    override func undo() {
        undoAction?()
        super.undo()
    }
    
    override func redo() {
        redoAction?()
        super.redo()
    }
    
}

