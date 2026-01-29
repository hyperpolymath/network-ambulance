// SPDX-License-Identifier: PMPL-1.0-or-later
/**
 * Routing diagnostics
 */
module core.diagnostics.routing;

import platform;
import std.algorithm;
import std.array;
import std.format;

/// Routing diagnostic results
struct RoutingDiagnostics {
    Route[] routes;
    Route[] defaultRoutes;
    bool hasDefaultRoute;
    bool canReachGateway;
    string gatewayIP;
    string[] warnings;
    string[] recommendations;
}

/// Run routing diagnostics
RoutingDiagnostics diagnoseRouting(NetworkPlatform platform) @safe {
    RoutingDiagnostics result;

    result.routes = platform.getRoutes();
    result.defaultRoutes = result.routes.filter!(r => r.isDefault).array;
    result.hasDefaultRoute = result.defaultRoutes.length > 0;

    if (!result.hasDefaultRoute) {
        result.warnings ~= "No default route configured";
        result.recommendations ~= "Add default route via your gateway";
        return result;
    }

    // Check for multiple default routes (conflict)
    if (result.defaultRoutes.length > 1) {
        result.warnings ~= format("Multiple default routes detected (%d routes)",
                                   result.defaultRoutes.length);
        result.recommendations ~= "Remove duplicate default routes";
    }

    // Test gateway reachability
    auto primaryRoute = result.defaultRoutes[0];
    result.gatewayIP = primaryRoute.gateway;

    if (result.gatewayIP.length > 0) {
        result.canReachGateway = platform.pingIP(result.gatewayIP, 2);

        if (!result.canReachGateway) {
            result.warnings ~= format("Cannot reach gateway %s", result.gatewayIP);
            result.recommendations ~= "Check gateway configuration or network cable";
        }
    } else {
        result.warnings ~= "Default route has no gateway";
        result.recommendations ~= "Fix default route configuration";
    }

    return result;
}
