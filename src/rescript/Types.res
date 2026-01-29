// SPDX-License-Identifier: PMPL-1.0-or-later
// Type definitions for Network Ambulance

// DNS Server information
type dnsServer = {
  address: string,
  port: int,
  reachable: bool,
  latency_ms: option<float>,
}

// DNS Diagnostics
type dnsDiagnostics = {
  has_dns_servers: bool,
  can_resolve: bool,
  servers: array<dnsServer>,
  warnings: array<string>,
  recommendations: array<string>,
}

// Route information
type route = {
  destination: string,
  gateway: string,
  @as("interface") interface_: string,
  metric: int,
  is_default: bool,
}

// Routing Diagnostics
type routingDiagnostics = {
  has_default_route: bool,
  can_reach_gateway: bool,
  gateway_ip: string,
  routes: array<route>,
  default_routes: array<route>,
  warnings: array<string>,
  recommendations: array<string>,
}

// Connectivity Test
type connectivityTest = {
  target: string,
  reachable: bool,
  latency_ms: float,
  protocol: string,
}

// Connectivity Diagnostics
type connectivityDiagnostics = {
  has_internet: bool,
  has_dns: bool,
  avg_latency_ms: float,
  tests: array<connectivityTest>,
  warnings: array<string>,
  recommendations: array<string>,
}

// Interface information
type interfaceInfo = {
  name: string,
  mac_address: string,
  ipv4_addresses: array<string>,
  is_up: bool,
  has_carrier: bool,
  rx_bytes: float,
  tx_bytes: float,
  rx_packets: float,
  tx_packets: float,
}

// Interface Diagnostics
type interfaceDiagnostics = {
  interfaces: array<interfaceInfo>,
  up_interfaces: int,
  down_interfaces: int,
  no_carrier_interfaces: int,
  no_ip_interfaces: int,
  warnings: array<string>,
  recommendations: array<string>,
}

// Complete Diagnostic Result
type diagnosticResult = {
  version: string,
  tool: string,
  dns: dnsDiagnostics,
  routing: routingDiagnostics,
  connectivity: connectivityDiagnostics,
  interfaces: interfaceDiagnostics,
}

// Repair Results
type repairResult = {
  version: string,
  tool: string,
  dns_repair: {
    "success": bool,
    "backup_created": bool,
    "backup_path": string,
    "actions": array<string>,
    "errors": array<string>,
  },
  interface_repair: {
    "success": bool,
    "actions": array<string>,
    "errors": array<string>,
    "repaired_interfaces": array<interfaceInfo>,
  },
  routing_repair: {
    "success": bool,
    "actions": array<string>,
    "errors": array<string>,
    "added_routes": array<route>,
    "removed_routes": array<route>,
  },
}

// Application State
type networkState =
  | Unknown
  | Loading
  | Healthy(diagnosticResult)
  | Problems(diagnosticResult)
  | Repairing(string)
  | RepairComplete(repairResult)
  | Error(string)

// View Mode
type viewMode =
  | Dashboard
  | Diagnostics
  | Repairs
  | Settings
