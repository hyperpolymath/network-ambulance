// SPDX-License-Identifier: PMPL-1.0-or-later
// Tauri library exports

#[cfg(target_os = "android")]
use tauri::mobile_entry_point;

#[cfg(target_os = "android")]
#[mobile_entry_point]
fn android_main() {
    // Android-specific initialization
}

#[cfg(target_os = "ios")]
use tauri::mobile_entry_point;

#[cfg(target_os = "ios")]
#[mobile_entry_point]
fn ios_main() {
    // iOS-specific initialization
}
