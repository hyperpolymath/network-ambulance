// SPDX-License-Identifier: PMPL-1.0-or-later
// Application Entry Point

// Import global styles
%%private(external importCSS: string => unit = "default")
importCSS("../style.css")

// React 18 root API
type root

@module("react-dom/client")
external createRoot: Dom.element => root = "createRoot"

@send
external render: (root, React.element) => unit = "render"

// Mount application
switch document->Nullable.toOption {
| Some(doc) =>
  switch doc->Document.getElementById("root")->Nullable.toOption {
  | Some(rootElement) =>
    let root = createRoot(rootElement)
    root->render(<App />)
  | None => Console.error("Root element not found")
  }
| None => Console.error("Document not available")
}
