// SPDX-License-Identifier: PMPL-1.0-or-later
/**
 * Common types for platform abstraction
 */
module platform.types;

import std.typecons : Nullable;

/// Network interface information
struct InterfaceInfo {
    string name;              /// Interface name (e.g., "eth0", "wlan0")
    string macAddress;        /// MAC address (e.g., "00:11:22:33:44:55")
    string[] ipv4Addresses;   /// IPv4 addresses (CIDR notation)
    string[] ipv6Addresses;   /// IPv6 addresses
    bool isUp;                /// Interface is UP
    bool hasCarrier;          /// Link/carrier detected
    ulong rxBytes;            /// Received bytes
    ulong txBytes;            /// Transmitted bytes
    ulong rxPackets;          /// Received packets
    ulong txPackets;          /// Transmitted packets
}

/// DNS server information
struct DNSServer {
    string address;           /// DNS server IP
    ushort port = 53;         /// DNS server port
    bool reachable;           /// Server is reachable
    Nullable!double latencyMs; /// Query latency in milliseconds
}

/// Route table entry
struct Route {
    string destination;       /// Destination network (CIDR)
    string gateway;           /// Gateway IP
    string interfaceName;     /// Outgoing interface
    uint metric;              /// Route metric
    bool isDefault;           /// Is default route
}

/// Network connectivity status
enum ConnectivityStatus {
    Unknown,
    NoConnection,
    LimitedConnectivity,
    FullConnectivity
}

/// Diagnostic result
struct DiagnosticResult {
    bool success;             /// Diagnostic succeeded
    string message;           /// Human-readable message
    string[] details;         /// Detailed findings
    string[] suggestions;     /// Suggested fixes
}
