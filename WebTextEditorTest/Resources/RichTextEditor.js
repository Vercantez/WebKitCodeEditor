//var editor = document.getElementById("editor");
var myCodeMirror = CodeMirror(document.body, {
                              value: codeString,
                              mode: "swift",
                              theme: "dracula",
                              lineNumbers: true
                              });

myCodeMirror.on("change", function() {
                window.webkit.messageHandlers.heightDidChange.postMessage(document.body.offsetHeight);
                });

document.addEventListener("click", function() {
                        myCodeMirror.focus();
                        myCodeMirror.execCommand("goDocEnd");
                        }, false);

//richeditor.insertText = function(text) {
//    editor.innerHTML = text;
//    window.webkit.messageHandlers.heightDidChange.postMessage(document.body.offsetHeight);
//}

//editor.addEventListener("input", function() {
//    window.webkit.messageHandlers.textDidChange.postMessage(editor.innerHTML);
//}, false)
//
//document.addEventListener("selectionchange", function() {
//    window.webkit.messageHandlers.heightDidChange.postMessage(document.body.offsetHeight);
//}, false);

