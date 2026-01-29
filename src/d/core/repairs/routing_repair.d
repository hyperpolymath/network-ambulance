// SPDX-License-Identifier: PMPL-1.0-or-later
/**
 * Routing repair module
 */
module core.repairs.routing_repair;

import platform;
import core.diagnostics.routing;
import core.diagnostics.interfaces;
import std.algorithm;
import std.array;
import std.format;

/// Routing repair result
struct RoutingRepairResult {
    bool success;
    string[] actions;
    string[] errors;
    Route[] addedRoutes;
    Route[] removedRoutes;
}

/// Repair routing table
RoutingRepairResult repairRouting(NetworkPlatform platform, RoutingDiagnostics diag) @safe {
    RoutingRepairResult result;

    // Check if repair is needed
    if (diag.hasDefaultRoute && diag.canReachGateway && diag.defaultRoutes.length == 1) {
        result.success = true;
        result.actions ~= "Routing table is correct, no repair needed";
        return result;
    }

    // Repair: No default route
    if (!diag.hasDefaultRoute) {
        result.actions ~= "No default route found";

        // Try to detect gateway from interfaces
        auto ifaceDiag = diagnoseInterfaces(platform);
        auto upInterfaces = ifaceDiag.upInterfaces.filter!(i => i.ipv4Addresses.length > 0);

        if (!upInterfaces.empty) {
            // Get first interface with IP
            auto iface = upInterfaces.front;
            string gateway = detectGateway(iface);

            if (gateway.length > 0) {
                result.actions ~= format("Detected possible gateway: %s (from interface %s)", gateway, iface.name);

                // Test gateway reachability
                if (platform.pingIP(gateway, 2)) {
                    result.actions ~= format("Gateway %s is reachable", gateway);

                    // Add default route
                    if (platform.addDefaultRoute(gateway, iface.name)) {
                        Route newRoute;
                        newRoute.destination = "0.0.0.0/0";
                        newRoute.gateway = gateway;
                        newRoute.interfaceName = iface.name;
                        newRoute.isDefault = true;

                        result.addedRoutes ~= newRoute;
                        result.actions ~= format("✓ Added default route via %s dev %s", gateway, iface.name);
                        result.success = true;
                    } else {
                        result.errors ~= "Failed to add default route";
                    }
                } else {
                    result.errors ~= format("Gateway %s is not reachable, cannot add route", gateway);
                }
            } else {
                result.errors ~= "Could not detect gateway from network configuration";
                result.actions ~= "Manual intervention required: configure default gateway";
            }
        } else {
            result.errors ~= "No UP interfaces with IP address found";
            result.actions ~= "Fix interface issues first (run: repair interface)";
        }

        return result;
    }

    // Repair: Multiple default routes (conflict)
    if (diag.defaultRoutes.length > 1) {
        result.actions ~= format("Multiple default routes detected (%d routes)", diag.defaultRoutes.length);

        // Keep the one with lowest metric (highest priority)
        auto sortedRoutes = diag.defaultRoutes.sort!((a, b) => a.metric < b.metric).array;
        auto primaryRoute = sortedRoutes[0];

        result.actions ~= format("Primary route: via %s dev %s (metric: %d)",
                                 primaryRoute.gateway, primaryRoute.interfaceName, primaryRoute.metric);

        // Remove duplicates
        foreach (route; sortedRoutes[1..$]) {
            result.actions ~= format("Removing duplicate: via %s dev %s (metric: %d)",
                                     route.gateway, route.interfaceName, route.metric);

            if (platform.deleteRoute("default")) {
                result.removedRoutes ~= route;
                result.actions ~= "✓ Removed duplicate route";
            } else {
                result.errors ~= "Failed to remove duplicate route";
            }
        }

        // Re-add primary route to ensure it exists
        if (result.removedRoutes.length > 0) {
            if (platform.addDefaultRoute(primaryRoute.gateway, primaryRoute.interfaceName)) {
                result.addedRoutes ~= primaryRoute;
                result.actions ~= "✓ Ensured primary route is active";
                result.success = true;
            } else {
                result.errors ~= "Failed to ensure primary route";
            }
        }
    }

    // Repair: Unreachable gateway
    if (diag.hasDefaultRoute && !diag.canReachGateway) {
        result.actions ~= format("Default gateway %s is unreachable", diag.gatewayIP);

        // Get interface diagnostics to check carrier
        auto ifaceDiag = diagnoseInterfaces(platform);
        auto primaryRoute = diag.defaultRoutes[0];
        auto routeIface = ifaceDiag.interfaces.filter!(i => i.name == primaryRoute.interfaceName);

        if (!routeIface.empty && !routeIface.front.hasCarrier) {
            result.errors ~= format("Interface %s has no carrier (cable disconnected?)", primaryRoute.interfaceName);
            result.actions ~= "Fix interface issues first (run: repair interface)";
        } else if (!routeIface.empty && routeIface.front.ipv4Addresses.length == 0) {
            result.errors ~= format("Interface %s has no IP address", primaryRoute.interfaceName);
            result.actions ~= "Fix interface issues first (run: repair interface)";
        } else {
            result.errors ~= "Gateway may be down or network configuration is incorrect";
            result.actions ~= "Manual intervention required: check gateway device and network";
        }
    }

    // Determine overall success
    if (result.errors.length == 0 || result.addedRoutes.length > 0) {
        result.success = true;
    }

    return result;
}

/// Detect gateway IP from interface configuration
string detectGateway(InterfaceInfo iface) @safe pure {
    if (iface.ipv4Addresses.length == 0) {
        return "";
    }

    // Parse first IP/netmask (e.g., "192.168.1.168/24")
    import std.string : split, indexOf;
    import std.conv : to;

    auto parts = iface.ipv4Addresses[0].split("/");
    if (parts.length != 2) {
        return "";
    }

    string ip = parts[0];
    auto octets = ip.split(".");

    if (octets.length != 4) {
        return "";
    }

    // Common gateway patterns:
    // If IP is X.X.X.Y, gateway is typically X.X.X.1 or X.X.X.254
    try {
        uint lastOctet = octets[3].to!uint;

        // If host is .1, gateway might be .254
        if (lastOctet == 1) {
            return format("%s.%s.%s.254", octets[0], octets[1], octets[2]);
        }

        // Otherwise, gateway is typically .1
        return format("%s.%s.%s.1", octets[0], octets[1], octets[2]);
    } catch (Exception e) {
        return "";
    }
}
