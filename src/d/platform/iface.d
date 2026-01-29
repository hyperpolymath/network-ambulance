// SPDX-License-Identifier: PMPL-1.0-or-later
/**
 * Platform interface - must be implemented by each platform
 */
module platform.iface;

import platform.types;

/// Platform-specific network operations interface
interface NetworkPlatform {
    /// Get all network interfaces
    InterfaceInfo[] getInterfaces() @safe;

    /// Get specific interface by name
    InterfaceInfo getInterface(string name) @safe;

    /// Bring interface up
    bool bringInterfaceUp(string name) @safe;

    /// Bring interface down
    bool bringInterfaceDown(string name) @safe;

    /// Renew DHCP lease
    bool renewDHCP(string interfaceName) @safe;

    /// Get DNS servers
    DNSServer[] getDNSServers() @safe;

    /// Set DNS servers
    bool setDNSServers(DNSServer[] servers) @safe;

    /// Get routing table
    Route[] getRoutes() @safe;

    /// Add default route
    bool addDefaultRoute(string gateway, string interfaceName) @safe;

    /// Delete route
    bool deleteRoute(string destination) @safe;

    /// Test connectivity to IP
    bool pingIP(string ip, uint timeout = 5) @safe;

    /// Test DNS resolution
    bool testDNS(string hostname, string dnsServer) @safe;

    /// Get platform name
    string getPlatformName() @safe nothrow pure;
}
