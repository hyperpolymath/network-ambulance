// SPDX-License-Identifier: PMPL-1.0-or-later
/**
 * IPv6 diagnostics - dual-stack, transition mechanisms, addressing
 */
module core.diagnostics.ipv6;

import platform;
import std.algorithm;
import std.array;
import std.format;
import std.string;
import std.conv : to;

/// IPv6 address scope types
enum IPv6Scope {
    LinkLocal,      // fe80::/10 - link-local addresses
    SiteLocal,      // fec0::/10 - deprecated site-local
    UniqueLocal,    // fc00::/7  - ULA (unique local addresses)
    Global,         // 2000::/3  - global unicast
    Multicast,      // ff00::/8  - multicast
    Loopback,       // ::1/128   - loopback
    Unspecified,    // ::/128    - unspecified
    IPv4Mapped,     // ::ffff:0:0/96 - IPv4-mapped
    IPv4Compatible, // ::/96     - deprecated IPv4-compatible
    Teredo,         // 2001::/32 - Teredo tunneling
    SixToFour,      // 2002::/16 - 6to4 tunneling
    Documentation,  // 2001:db8::/32 - documentation
}

/// IPv6 address configuration method
enum IPv6ConfigMethod {
    Unknown,
    SLAAC,          // Stateless Address Autoconfiguration
    DHCPv6,         // DHCPv6 stateful
    Static,         // Manually configured
    PrivacyExt,     // SLAAC + privacy extensions (RFC 4941)
    Temporary,      // Temporary address
}

/// IPv6 address information
struct IPv6Address {
    string address;
    IPv6Scope scope_;
    IPv6ConfigMethod method;
    bool isPreferred;      // Not deprecated
    bool isTemporary;      // Privacy extension temporary address
    uint prefixLength;
    string interface_;
}

/// IPv6 router information
struct IPv6Router {
    string address;
    string interface_;
    bool isReachable;
    uint preference;       // Router preference (high/medium/low)
    uint lifetime;         // Router lifetime in seconds
}

/// IPv6 neighbor cache entry
struct IPv6Neighbor {
    string address;
    string macAddress;
    string state;          // REACHABLE, STALE, DELAY, PROBE, FAILED
    string interface_;
}

/// Transition mechanism info
struct TransitionMechanism {
    string type;           // 6to4, Teredo, ISATAP, NAT64, DNS64
    bool active;
    string endpoint;       // Relay/gateway address
    string[] warnings;
}

/// IPv6 diagnostics result
struct IPv6Diagnostics {
    // Addresses
    IPv6Address[] addresses;
    bool hasLinkLocal;
    bool hasGlobal;
    bool hasULA;
    bool hasPrivacyExtensions;

    // Routing
    IPv6Router[] routers;
    bool hasDefaultRoute;
    string defaultGateway;

    // Neighbor Discovery
    IPv6Neighbor[] neighbors;
    bool ndpWorking;

    // Dual-stack
    bool dualStackEnabled;
    bool ipv4Preferred;
    bool ipv6Preferred;

    // Transition mechanisms
    TransitionMechanism[] transitionMechs;
    bool hasTeredoTunnel;
    bool has6to4Tunnel;
    bool hasNAT64;

    // Connectivity
    bool canReachIPv6Internet;
    bool canResolveDNSAAAA;
    double ipv6Latency;

    // Issues
    string[] warnings;
    string[] recommendations;
}

/// Determine IPv6 address scope
IPv6Scope getIPv6Scope(string addr) @safe pure {
    if (addr.startsWith("fe80:")) return IPv6Scope.LinkLocal;
    if (addr.startsWith("fec0:")) return IPv6Scope.SiteLocal;
    if (addr.startsWith("fc") || addr.startsWith("fd")) return IPv6Scope.UniqueLocal;
    if (addr.startsWith("ff")) return IPv6Scope.Multicast;
    if (addr == "::1") return IPv6Scope.Loopback;
    if (addr == "::") return IPv6Scope.Unspecified;
    if (addr.startsWith("::ffff:")) return IPv6Scope.IPv4Mapped;
    if (addr.startsWith("2001:0:")) return IPv6Scope.Teredo;
    if (addr.startsWith("2001:")) return IPv6Scope.Teredo;  // Teredo prefix
    if (addr.startsWith("2002:")) return IPv6Scope.SixToFour;
    if (addr.startsWith("2001:db8:")) return IPv6Scope.Documentation;

    // Global unicast (2000::/3)
    return IPv6Scope.Global;
}

/// Run IPv6 diagnostics
IPv6Diagnostics diagnoseIPv6(NetworkPlatform platform) @safe {
    IPv6Diagnostics result;

    // Get all interfaces to find IPv6 addresses
    auto interfaces = platform.getInterfaces();

    foreach (iface; interfaces) {
        // Parse IPv6 addresses from interface
        foreach (addr; iface.ipv4Addresses) {  // Note: Need to add ipv6Addresses to InterfaceInfo
            if (addr.canFind(":")) {  // Simple IPv6 detection
                IPv6Address ipv6addr;

                // Parse address and prefix
                auto parts = addr.split("/");
                ipv6addr.address = parts[0];
                ipv6addr.prefixLength = parts.length > 1 ? parts[1].to!uint : 64;
                ipv6addr.interface_ = iface.name;
                ipv6addr.scope_ = getIPv6Scope(ipv6addr.address);

                // Determine configuration method (simplified)
                if (ipv6addr.scope_ == IPv6Scope.LinkLocal) {
                    ipv6addr.method = IPv6ConfigMethod.SLAAC;
                } else if (ipv6addr.scope_ == IPv6Scope.Global) {
                    // Check if temporary (privacy extension)
                    ipv6addr.method = IPv6ConfigMethod.SLAAC;
                }

                result.addresses ~= ipv6addr;

                // Update flags
                if (ipv6addr.scope_ == IPv6Scope.LinkLocal) result.hasLinkLocal = true;
                if (ipv6addr.scope_ == IPv6Scope.Global) result.hasGlobal = true;
                if (ipv6addr.scope_ == IPv6Scope.UniqueLocal) result.hasULA = true;
            }
        }
    }

    // Check for dual-stack (both IPv4 and IPv6)
    bool hasIPv4 = interfaces.any!(i => i.ipv4Addresses.length > 0 &&
                                        !i.ipv4Addresses[0].startsWith("127."));
    result.dualStackEnabled = hasIPv4 && (result.hasLinkLocal || result.hasGlobal);

    // Detect transition mechanisms
    result.transitionMechs = detectTransitionMechanisms(result.addresses);
    result.hasTeredoTunnel = result.transitionMechs.any!(m => m.type == "Teredo");
    result.has6to4Tunnel = result.transitionMechs.any!(m => m.type == "6to4");

    // IPv6 connectivity test (ping IPv6 DNS servers)
    result.canReachIPv6Internet = platform.pingIP("2001:4860:4860::8888", 5);  // Google IPv6 DNS

    // DNS AAAA record resolution test
    result.canResolveDNSAAAA = platform.testDNS("ipv6.google.com", "2001:4860:4860::8888");

    // Generate warnings and recommendations
    generateIPv6Recommendations(result);

    return result;
}

/// Detect IPv6 transition mechanisms
TransitionMechanism[] detectTransitionMechanisms(IPv6Address[] addresses) @safe pure {
    TransitionMechanism[] mechanisms;

    foreach (addr; addresses) {
        TransitionMechanism mech;

        switch (addr.scope_) {
            case IPv6Scope.Teredo:
                mech.type = "Teredo";
                mech.active = true;
                mech.endpoint = addr.address;
                mech.warnings ~= "Teredo tunneling active - may have NAT traversal issues";
                mechanisms ~= mech;
                break;

            case IPv6Scope.SixToFour:
                mech.type = "6to4";
                mech.active = true;
                mech.endpoint = addr.address;
                mech.warnings ~= "6to4 tunneling active - relies on public IPv4 address";
                mechanisms ~= mech;
                break;

            default:
                break;
        }
    }

    return mechanisms;
}

/// Generate IPv6-specific recommendations
void generateIPv6Recommendations(ref IPv6Diagnostics result) @safe {
    // No IPv6 at all
    if (result.addresses.length == 0) {
        result.warnings ~= "No IPv6 addresses configured";
        result.recommendations ~= "Enable IPv6 in network settings";
        result.recommendations ~= "Check if ISP provides IPv6 connectivity";
        return;
    }

    // Only link-local (no global connectivity)
    if (result.hasLinkLocal && !result.hasGlobal && !result.hasULA) {
        result.warnings ~= "Only link-local IPv6 address - no internet connectivity";
        result.recommendations ~= "Check IPv6 router advertisements (RA)";
        result.recommendations ~= "Verify DHCPv6 server availability";
        result.recommendations ~= "Check if IPv6 prefix delegation is working";
    }

    // Has global but cannot reach internet
    if (result.hasGlobal && !result.canReachIPv6Internet) {
        result.warnings ~= "IPv6 global address present but no internet connectivity";
        result.recommendations ~= "Check IPv6 default route";
        result.recommendations ~= "Verify IPv6 firewall rules";
        result.recommendations ~= "Test IPv6 gateway reachability";
    }

    // DNS AAAA resolution failing
    if (result.hasGlobal && result.canReachIPv6Internet && !result.canResolveDNSAAAA) {
        result.warnings ~= "IPv6 connectivity OK but DNS AAAA records not resolving";
        result.recommendations ~= "Check DNS server supports IPv6";
        result.recommendations ~= "Verify DNS64 not interfering with AAAA queries";
    }

    // Transition mechanisms (generally suboptimal)
    if (result.hasTeredoTunnel) {
        result.warnings ~= "Using Teredo tunneling - suboptimal performance";
        result.recommendations ~= "Request native IPv6 from ISP";
        result.recommendations ~= "Consider disabling Teredo if not needed";
    }

    if (result.has6to4Tunnel) {
        result.warnings ~= "Using 6to4 tunneling - deprecated and unreliable";
        result.recommendations ~= "Disable 6to4 and use native IPv6 or modern tunnel";
    }

    // No privacy extensions (potential privacy issue)
    if (result.hasGlobal && !result.hasPrivacyExtensions) {
        result.warnings ~= "No IPv6 privacy extensions - stable addresses may track you";
        result.recommendations ~= "Enable IPv6 privacy extensions (RFC 4941)";
        result.recommendations ~= "Use temporary addresses for outgoing connections";
    }

    // Dual-stack preference issues
    if (result.dualStackEnabled && result.ipv4Preferred) {
        result.warnings ~= "Dual-stack but IPv4 preferred - not using IPv6 optimally";
        result.recommendations ~= "Configure Happy Eyeballs for better dual-stack";
        result.recommendations ~= "Check gai.conf for address selection policy";
    }
}
