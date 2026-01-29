// SPDX-License-Identifier: PMPL-1.0-or-later
/**
 * Interface repair module
 */
module core.repairs.interface_repair;

import platform;
import core.diagnostics.interfaces;
import std.algorithm;
import std.array;
import std.format;

/// Interface repair result
struct InterfaceRepairResult {
    bool success;
    string[] actions;
    string[] errors;
    InterfaceInfo[] repairedInterfaces;
}

/// Repair network interfaces
InterfaceRepairResult repairInterfaces(NetworkPlatform platform, InterfaceDiagnostics diag) @safe {
    InterfaceRepairResult result;

    // Check if repair is needed
    if (diag.upInterfaces.length > 0 && diag.downInterfaces.length == 0) {
        auto upWithIP = diag.upInterfaces.filter!(i => i.ipv4Addresses.length > 0);
        if (!upWithIP.empty) {
            result.success = true;
            result.actions ~= "Network interfaces are working correctly, no repair needed";
            return result;
        }
    }

    result.actions ~= format("Found %d interface(s) with issues",
                             diag.downInterfaces.length + diag.noCarrierInterfaces.length + diag.noIPInterfaces.length);

    // Repair interfaces with no carrier (cable/link issues)
    foreach (iface; diag.noCarrierInterfaces) {
        // Skip loopback
        if (iface.name == "lo") continue;

        result.actions ~= format("Interface %s: No carrier detected", iface.name);

        // Try bringing interface down and up (reinitialize)
        if (platform.bringInterfaceDown(iface.name)) {
            result.actions ~= format("  Brought %s down", iface.name);

            import core.thread : Thread;
            import core.time : dur;
            Thread.sleep(dur!"seconds"(2));  // Wait 2 seconds

            if (platform.bringInterfaceUp(iface.name)) {
                result.actions ~= format("  Brought %s up", iface.name);

                // Check if carrier is now present
                auto newDiag = diagnoseInterfaces(platform);
                auto updatedIface = newDiag.interfaces.filter!(i => i.name == iface.name);

                if (!updatedIface.empty && updatedIface.front.hasCarrier) {
                    result.actions ~= format("  ✓ %s now has carrier", iface.name);
                    result.repairedInterfaces ~= updatedIface.front;
                } else {
                    result.errors ~= format("  ✗ %s still has no carrier (check cable/connection)", iface.name);
                }
            } else {
                result.errors ~= format("  ✗ Failed to bring %s up", iface.name);
            }
        } else {
            result.errors ~= format("  ✗ Failed to bring %s down", iface.name);
        }
    }

    // Repair interfaces that are down but have carrier
    foreach (iface; diag.downInterfaces) {
        // Skip loopback and interfaces without carrier (already handled above)
        if (iface.name == "lo") continue;
        if (!iface.hasCarrier) continue;

        result.actions ~= format("Interface %s: DOWN but has carrier", iface.name);

        if (platform.bringInterfaceUp(iface.name)) {
            result.actions ~= format("  Brought %s up", iface.name);

            // Check if interface is now up
            auto newDiag = diagnoseInterfaces(platform);
            auto updatedIface = newDiag.interfaces.filter!(i => i.name == iface.name);

            if (!updatedIface.empty && updatedIface.front.isUp) {
                result.actions ~= format("  ✓ %s is now UP", iface.name);
                result.repairedInterfaces ~= updatedIface.front;
            } else {
                result.errors ~= format("  ✗ %s failed to come up", iface.name);
            }
        } else {
            result.errors ~= format("  ✗ Failed to bring %s up", iface.name);
        }
    }

    // Repair interfaces with no IP address
    foreach (iface; diag.noIPInterfaces) {
        // Skip loopback
        if (iface.name == "lo") continue;

        result.actions ~= format("Interface %s: UP but no IP address", iface.name);

        // Try DHCP renewal
        if (platform.renewDHCP(iface.name)) {
            result.actions ~= format("  Requested DHCP renewal for %s", iface.name);

            import core.thread : Thread;
            import core.time : dur;
            Thread.sleep(dur!"seconds"(5));  // Wait for DHCP response

            // Check if IP was assigned
            auto newDiag = diagnoseInterfaces(platform);
            auto updatedIface = newDiag.interfaces.filter!(i => i.name == iface.name);

            if (!updatedIface.empty && updatedIface.front.ipv4Addresses.length > 0) {
                result.actions ~= format("  ✓ %s got IP: %s", iface.name, updatedIface.front.ipv4Addresses);
                result.repairedInterfaces ~= updatedIface.front;
            } else {
                result.errors ~= format("  ✗ %s still has no IP (DHCP server may be unreachable)", iface.name);
            }
        } else {
            result.errors ~= format("  ✗ Failed to renew DHCP for %s", iface.name);
        }
    }

    // Determine overall success
    result.success = result.repairedInterfaces.length > 0 || result.errors.length == 0;

    if (result.repairedInterfaces.length > 0) {
        result.actions ~= format("\n✓ Successfully repaired %d interface(s)", result.repairedInterfaces.length);
    } else if (result.errors.length == 0) {
        result.actions ~= "\n✓ No repairs needed";
    } else {
        result.actions ~= format("\n✗ Failed to repair some interfaces (%d errors)", result.errors.length);
    }

    return result;
}

/// Restart network service (NetworkManager or systemd-networkd)
bool restartNetworkService(NetworkPlatform platform) @trusted {
    import std.process : execute;

    // Try NetworkManager first
    auto nmResult = execute(["systemctl", "is-active", "NetworkManager"]);
    if (nmResult.status == 0) {
        auto restartResult = execute(["systemctl", "restart", "NetworkManager"]);
        return restartResult.status == 0;
    }

    // Try systemd-networkd
    auto networkdResult = execute(["systemctl", "is-active", "systemd-networkd"]);
    if (networkdResult.status == 0) {
        auto restartResult = execute(["systemctl", "restart", "systemd-networkd"]);
        return restartResult.status == 0;
    }

    return false;
}
