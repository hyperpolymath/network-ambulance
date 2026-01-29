// SPDX-License-Identifier: PMPL-1.0-or-later
/**
 * Network interface diagnostics
 */
module core.diagnostics.interfaces;

import platform;
import std.algorithm;
import std.array;

/// Interface diagnostic results
struct InterfaceDiagnostics {
    InterfaceInfo[] interfaces;
    InterfaceInfo[] upInterfaces;
    InterfaceInfo[] downInterfaces;
    InterfaceInfo[] noCarrierInterfaces;
    InterfaceInfo[] noIPInterfaces;
    string[] warnings;
    string[] recommendations;
}

/// Run interface diagnostics
InterfaceDiagnostics diagnoseInterfaces(NetworkPlatform platform) @safe {
    InterfaceDiagnostics result;

    result.interfaces = platform.getInterfaces();

    // Categorize interfaces
    result.upInterfaces = result.interfaces.filter!(i => i.isUp).array;
    result.downInterfaces = result.interfaces.filter!(i => !i.isUp).array;
    result.noCarrierInterfaces = result.interfaces.filter!(i => i.isUp && !i.hasCarrier).array;
    result.noIPInterfaces = result.interfaces.filter!(i => i.isUp && i.ipv4Addresses.length == 0).array;

    // Generate warnings and recommendations
    if (result.upInterfaces.length == 0) {
        result.warnings ~= "No network interfaces are up";
        result.recommendations ~= "Bring up at least one interface";
    }

    foreach (iface; result.noCarrierInterfaces) {
        result.warnings ~= "Interface " ~ iface.name ~ " is up but has no carrier (cable unplugged?)";
        result.recommendations ~= "Check cable connection for " ~ iface.name;
    }

    foreach (iface; result.noIPInterfaces) {
        result.warnings ~= "Interface " ~ iface.name ~ " has no IP address";
        result.recommendations ~= "Configure IP address or enable DHCP on " ~ iface.name;
    }

    return result;
}
