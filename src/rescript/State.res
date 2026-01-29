// SPDX-License-Identifier: PMPL-1.0-or-later
// TEA State Management (Model + Update)

open Types

// Model - Application State
type model = {
  state: networkState,
  view: viewMode,
  platform: option<string>,
  hasPrivileges: bool,
  error: option<string>,
}

// Message - User actions and events
type msg =
  | RunDiagnostics
  | DiagnosticsComplete(result<diagnosticResult, string>)
  | RunRepair(string)
  | RepairComplete(result<repairResult, string>)
  | ChangeView(viewMode)
  | CheckPrivileges
  | PrivilegesChecked(bool)
  | LoadPlatformInfo
  | PlatformInfoLoaded(string)
  | ClearError
  | NoOp

// Initial model
let init = (): model => {
  state: Unknown,
  view: Dashboard,
  platform: None,
  hasPrivileges: false,
  error: None,
}

// Command type for side effects
type cmd =
  | RunDiagnosticsCmd
  | RunRepairCmd(string)
  | CheckPrivilegesCmd
  | LoadPlatformInfoCmd
  | NoCmd

// Update function - Pure state transitions
let update = (model: model, msg: msg): (model, cmd) => {
  switch msg {
  | RunDiagnostics => (
      {...model, state: Loading, error: None},
      RunDiagnosticsCmd,
    )

  | DiagnosticsComplete(Ok(result)) => {
      // Determine if system is healthy
      let isHealthy =
        result.dns.can_resolve &&
        result.routing.has_default_route &&
        result.connectivity.has_internet

      let newState = isHealthy ? Healthy(result) : Problems(result)

      ({...model, state: newState, error: None}, NoCmd)
    }

  | DiagnosticsComplete(Error(err)) => (
      {...model, state: Error(err), error: Some(err)},
      NoCmd,
    )

  | RunRepair(target) => (
      {...model, state: Repairing(target), error: None},
      RunRepairCmd(target),
    )

  | RepairComplete(Ok(result)) => (
      {...model, state: RepairComplete(result), error: None},
      RunDiagnosticsCmd, // Re-run diagnostics after repair
    )

  | RepairComplete(Error(err)) => (
      {...model, state: Error(err), error: Some(err)},
      NoCmd,
    )

  | ChangeView(view) => ({...model, view: view}, NoCmd)

  | CheckPrivileges => (model, CheckPrivilegesCmd)

  | PrivilegesChecked(hasPriv) => ({...model, hasPrivileges: hasPriv}, NoCmd)

  | LoadPlatformInfo => (model, LoadPlatformInfoCmd)

  | PlatformInfoLoaded(platform) => (
      {...model, platform: Some(platform)},
      NoCmd,
    )

  | ClearError => ({...model, error: None}, NoCmd)

  | NoOp => (model, NoCmd)
  }
}

// Command executor - Handles side effects
let executeCmd = (cmd: cmd, dispatch: msg => unit): unit => {
  switch cmd {
  | RunDiagnosticsCmd =>
    TauriBindings.runDiagnostics()
    ->Promise.then(result => {
      dispatch(DiagnosticsComplete(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(err => {
      let message = switch err {
      | Exn.Error(obj) => Exn.message(obj)->Option.getOr("Unknown error")
      | _ => "Unknown error"
      }
      dispatch(DiagnosticsComplete(Error(message)))
      Promise.resolve()
    })
    ->ignore

  | RunRepairCmd(target) =>
    TauriBindings.runRepair(target)
    ->Promise.then(result => {
      dispatch(RepairComplete(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(err => {
      let message = switch err {
      | Exn.Error(obj) => Exn.message(obj)->Option.getOr("Unknown error")
      | _ => "Unknown error"
      }
      dispatch(RepairComplete(Error(message)))
      Promise.resolve()
    })
    ->ignore

  | CheckPrivilegesCmd =>
    TauriBindings.checkPrivileges()
    ->Promise.then(hasPriv => {
      dispatch(PrivilegesChecked(hasPriv))
      Promise.resolve()
    })
    ->Promise.catch(_ => {
      dispatch(PrivilegesChecked(false))
      Promise.resolve()
    })
    ->ignore

  | LoadPlatformInfoCmd =>
    TauriBindings.getPlatformInfo()
    ->Promise.then(platform => {
      dispatch(PlatformInfoLoaded(platform))
      Promise.resolve()
    })
    ->Promise.catch(_ => {
      dispatch(PlatformInfoLoaded("unknown"))
      Promise.resolve()
    })
    ->ignore

  | NoCmd => ()
  }
}
