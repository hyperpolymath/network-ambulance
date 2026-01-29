// SPDX-License-Identifier: PMPL-1.0-or-later
// Prevents additional console window on Windows in release builds
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use serde::{Deserialize, Serialize};
use std::process::Command;
use tauri::Manager;

#[derive(Debug, Serialize, Deserialize)]
struct DiagnosticResult {
    version: String,
    tool: String,
    dns: serde_json::Value,
    routing: serde_json::Value,
    connectivity: serde_json::Value,
    interfaces: serde_json::Value,
}

#[derive(Debug, Serialize, Deserialize)]
struct RepairResult {
    version: String,
    tool: String,
    dns_repair: serde_json::Value,
    interface_repair: serde_json::Value,
    routing_repair: serde_json::Value,
}

/// Run network diagnostics by calling the D backend
#[tauri::command]
async fn run_diagnostics() -> Result<DiagnosticResult, String> {
    let output = Command::new("./bin/network-ambulance-d")
        .args(["diagnose", "--json"])
        .output()
        .map_err(|e| format!("Failed to execute D backend: {}", e))?;

    if !output.status.success() {
        return Err(format!(
            "D backend failed: {}",
            String::from_utf8_lossy(&output.stderr)
        ));
    }

    let result: DiagnosticResult = serde_json::from_slice(&output.stdout)
        .map_err(|e| format!("Failed to parse JSON: {}", e))?;

    Ok(result)
}

/// Run network repairs by calling the D backend
#[tauri::command]
async fn run_repair(target: String) -> Result<RepairResult, String> {
    // Check for root/admin privileges
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        let metadata = std::fs::metadata("/").map_err(|e| e.to_string())?;
        if metadata.permissions().mode() & 0o700 != 0o700 {
            return Err("Repair operations require administrator privileges".to_string());
        }
    }

    let output = Command::new("./bin/network-ambulance-d")
        .args(["repair", &target, "--json"])
        .output()
        .map_err(|e| format!("Failed to execute D backend: {}", e))?;

    if !output.status.success() {
        return Err(format!(
            "D backend repair failed: {}",
            String::from_utf8_lossy(&output.stderr)
        ));
    }

    let result: RepairResult = serde_json::from_slice(&output.stdout)
        .map_err(|e| format!("Failed to parse JSON: {}", e))?;

    Ok(result)
}

/// Check if running with elevated privileges
#[tauri::command]
async fn check_privileges() -> Result<bool, String> {
    #[cfg(unix)]
    {
        Ok(unsafe { libc::geteuid() } == 0)
    }

    #[cfg(windows)]
    {
        // Windows privilege check would go here
        Ok(false)
    }

    #[cfg(not(any(unix, windows)))]
    {
        Ok(false)
    }
}

/// Get platform information
#[tauri::command]
async fn get_platform_info() -> Result<String, String> {
    Ok(std::env::consts::OS.to_string())
}

fn main() {
    tauri::Builder::default()
        .plugin(tauri_plugin_shell::init())
        .invoke_handler(tauri::generate_handler![
            run_diagnostics,
            run_repair,
            check_privileges,
            get_platform_info
        ])
        .setup(|app| {
            #[cfg(debug_assertions)]
            {
                let window = app.get_webview_window("main").unwrap();
                window.open_devtools();
            }
            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
