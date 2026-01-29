// SPDX-License-Identifier: PMPL-1.0-or-later
// Main Application Component (TEA View)

open Types
open State

// Helper to render status indicator
let statusIcon = (isOk: bool): string => isOk ? "✓" : "✗"

let statusColor = (isOk: bool): string => isOk ? "green" : "red"

// Render DNS diagnostics
let renderDNS = (dns: dnsDiagnostics) => {
  <div className="diagnostic-section">
    <h3> {React.string("DNS Diagnostics")} </h3>
    <div className="status-grid">
      <div className={`status-item ${statusColor(dns.has_dns_servers)}`}>
        <span className="icon"> {React.string(statusIcon(dns.has_dns_servers))} </span>
        <span> {React.string(`DNS Servers: ${Int.toString(Array.length(dns.servers))}`)} </span>
      </div>
      <div className={`status-item ${statusColor(dns.can_resolve)}`}>
        <span className="icon"> {React.string(statusIcon(dns.can_resolve))} </span>
        <span> {React.string("Resolution: ")} </span>
        <span> {React.string(dns.can_resolve ? "Working" : "Failed")} </span>
      </div>
    </div>
    {Array.length(dns.warnings) > 0
      ? <div className="warnings">
          <h4> {React.string("Warnings:")} </h4>
          {dns.warnings
          ->Array.map(w => <div key={w} className="warning"> {React.string(w)} </div>)
          ->React.array}
        </div>
      : React.null}
  </div>
}

// Render routing diagnostics
let renderRouting = (routing: routingDiagnostics) => {
  <div className="diagnostic-section">
    <h3> {React.string("Routing Diagnostics")} </h3>
    <div className="status-grid">
      <div className={`status-item ${statusColor(routing.has_default_route)}`}>
        <span className="icon"> {React.string(statusIcon(routing.has_default_route))} </span>
        <span> {React.string("Default Route: ")} </span>
        <span> {React.string(routing.has_default_route ? "Present" : "Missing")} </span>
      </div>
      <div className={`status-item ${statusColor(routing.can_reach_gateway)}`}>
        <span className="icon"> {React.string(statusIcon(routing.can_reach_gateway))} </span>
        <span> {React.string("Gateway: ")} </span>
        <span> {React.string(routing.can_reach_gateway ? routing.gateway_ip : "Unreachable")} </span>
      </div>
    </div>
  </div>
}

// Render connectivity diagnostics
let renderConnectivity = (conn: connectivityDiagnostics) => {
  <div className="diagnostic-section">
    <h3> {React.string("Connectivity Diagnostics")} </h3>
    <div className="status-grid">
      <div className={`status-item ${statusColor(conn.has_internet)}`}>
        <span className="icon"> {React.string(statusIcon(conn.has_internet))} </span>
        <span> {React.string("Internet: ")} </span>
        <span> {React.string(conn.has_internet ? "Connected" : "Disconnected")} </span>
      </div>
      <div className={`status-item ${statusColor(conn.has_dns)}`}>
        <span className="icon"> {React.string(statusIcon(conn.has_dns))} </span>
        <span> {React.string("DNS: ")} </span>
        <span> {React.string(conn.has_dns ? "Working" : "Failed")} </span>
      </div>
      <div className="status-item">
        <span> {React.string(`Avg Latency: ${Float.toString(conn.avg_latency_ms)}ms`)} </span>
      </div>
    </div>
  </div>
}

// Render interface diagnostics
let renderInterfaces = (ifaces: interfaceDiagnostics) => {
  <div className="diagnostic-section">
    <h3> {React.string("Network Interfaces")} </h3>
    <div className="status-grid">
      <div className="status-item">
        <span> {React.string(`Total: ${Int.toString(ifaces.up_interfaces + ifaces.down_interfaces)}`)} </span>
      </div>
      <div className={`status-item ${statusColor(ifaces.up_interfaces > 0)}`}>
        <span> {React.string(`UP: ${Int.toString(ifaces.up_interfaces)}`)} </span>
      </div>
      <div className={`status-item ${statusColor(ifaces.down_interfaces == 0)}`}>
        <span> {React.string(`DOWN: ${Int.toString(ifaces.down_interfaces)}`)} </span>
      </div>
    </div>
  </div>
}

// Dashboard view
let renderDashboard = (result: diagnosticResult, dispatch: msg => unit) => {
  let isHealthy =
    result.dns.can_resolve &&
    result.routing.has_default_route &&
    result.connectivity.has_internet

  <div className="dashboard">
    <div className={`health-status ${isHealthy ? "healthy" : "problems"}`}>
      <h2> {React.string(isHealthy ? "✓ System Healthy" : "⚠ Issues Detected")} </h2>
    </div>
    {renderDNS(result.dns)}
    {renderRouting(result.routing)}
    {renderConnectivity(result.connectivity)}
    {renderInterfaces(result.interfaces)}
    <div className="actions">
      <button onClick={_ => dispatch(RunDiagnostics)}>
        {React.string("Refresh Diagnostics")}
      </button>
      {!isHealthy
        ? <button onClick={_ => dispatch(RunRepair("all"))} className="repair-btn">
            {React.string("Repair All Issues")}
          </button>
        : React.null}
    </div>
  </div>
}

// Main App component
@react.component
let make = () => {
  let (model, setModel) = React.useState(() => init())

  let dispatch = (msg: msg): unit => {
    let (newModel, cmd) = update(model, msg)
    setModel(_ => newModel)
    executeCmd(cmd, dispatch)
  }

  // Load platform info on mount
  React.useEffect0(() => {
    dispatch(LoadPlatformInfo)
    dispatch(CheckPrivileges)
    None
  })

  // Render navigation
  let renderNav = () => {
    <nav className="nav">
      <button
        onClick={_ => dispatch(ChangeView(Dashboard))}
        className={model.view == Dashboard ? "active" : ""}>
        {React.string("Dashboard")}
      </button>
      <button
        onClick={_ => dispatch(ChangeView(Diagnostics))}
        className={model.view == Diagnostics ? "active" : ""}>
        {React.string("Diagnostics")}
      </button>
      <button
        onClick={_ => dispatch(ChangeView(Repairs))}
        className={model.view == Repairs ? "active" : ""}>
        {React.string("Repairs")}
      </button>
      <button
        onClick={_ => dispatch(ChangeView(Settings))}
        className={model.view == Settings ? "active" : ""}>
        {React.string("Settings")}
      </button>
    </nav>
  }

  // Render content based on state
  let renderContent = () => {
    switch model.state {
    | Unknown =>
      <div className="welcome">
        <h1> {React.string("Network Ambulance")} </h1>
        <p> {React.string("Cross-platform network diagnostics and repair")} </p>
        <button onClick={_ => dispatch(RunDiagnostics)} className="primary-btn">
          {React.string("Run Diagnostics")}
        </button>
      </div>

    | Loading =>
      <div className="loading">
        <div className="spinner" />
        <p> {React.string("Running diagnostics...")} </p>
      </div>

    | Healthy(result) | Problems(result) => renderDashboard(result, dispatch)

    | Repairing(target) =>
      <div className="loading">
        <div className="spinner" />
        <p> {React.string(`Repairing ${target}...`)} </p>
      </div>

    | RepairComplete(result) =>
      <div className="repair-result">
        <h2> {React.string("Repair Complete")} </h2>
        <div className="repair-summary">
          <div className={`repair-status ${result.dns_repair.success ? "success" : "failed"}`}>
            <h3> {React.string("DNS Repair")} </h3>
            <p> {React.string(result.dns_repair.success ? "✓ Success" : "✗ Failed")} </p>
          </div>
          <div
            className={`repair-status ${result.interface_repair.success ? "success" : "failed"}`}>
            <h3> {React.string("Interface Repair")} </h3>
            <p> {React.string(result.interface_repair.success ? "✓ Success" : "✗ Failed")} </p>
          </div>
          <div className={`repair-status ${result.routing_repair.success ? "success" : "failed"}`}>
            <h3> {React.string("Routing Repair")} </h3>
            <p> {React.string(result.routing_repair.success ? "✓ Success" : "✗ Failed")} </p>
          </div>
        </div>
        <button onClick={_ => dispatch(RunDiagnostics)} className="primary-btn">
          {React.string("Run Diagnostics Again")}
        </button>
      </div>

    | Error(err) =>
      <div className="error">
        <h2> {React.string("Error")} </h2>
        <p> {React.string(err)} </p>
        <button onClick={_ => dispatch(ClearError)}> {React.string("Dismiss")} </button>
      </div>
    }
  }

  <div className="app">
    <header>
      <h1> {React.string("Network Ambulance")} </h1>
      {model.platform
      ->Option.map(p => <span className="platform"> {React.string(p)} </span>)
      ->Option.getOr(React.null)}
    </header>
    {renderNav()}
    <main> {renderContent()} </main>
  </div>
}
