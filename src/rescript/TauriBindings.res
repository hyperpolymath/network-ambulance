// SPDX-License-Identifier: PMPL-1.0-or-later
// Tauri IPC bindings

// External Tauri invoke function
@module("@tauri-apps/api/core")
external invoke: (string, 'a) => promise<'b> = "invoke"

@module("@tauri-apps/api/core")
external invokeSimple: string => promise<'a> = "invoke"

// Run diagnostics command
let runDiagnostics = (): promise<Types.diagnosticResult> => {
  invokeSimple("run_diagnostics")
}

// Run repair command
let runRepair = (target: string): promise<Types.repairResult> => {
  invoke("run_repair", {"target": target})
}

// Check if running with elevated privileges
let checkPrivileges = (): promise<bool> => {
  invokeSimple("check_privileges")
}

// Get platform information
let getPlatformInfo = (): promise<string> => {
  invokeSimple("get_platform_info")
}

// Event listeners for Tauri events
@module("@tauri-apps/api/event")
external listen: (string, 'payload => unit) => promise<unit> = "listen"

@module("@tauri-apps/api/event")
external emit: (string, 'payload) => promise<unit> = "emit"

// Window management
@module("@tauri-apps/api/window")
external getCurrentWindow: unit => 'window = "getCurrent"

type window

@send
external setTitle: (window, string) => promise<unit> = "setTitle"

@send
external minimize: window => promise<unit> = "minimize"

@send
external maximize: window => promise<unit> = "maximize"

@send
external close: window => promise<unit> = "close"
