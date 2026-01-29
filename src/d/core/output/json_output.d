// SPDX-License-Identifier: PMPL-1.0-or-later
/**
 * JSON output formatter
 */
module core.output.json_output;

import std.json;
import std.conv : to;
import std.array;
import platform;
import core.diagnostics.dns;
import core.diagnostics.interfaces;
import core.diagnostics.routing;
import core.diagnostics.connectivity;
import core.repairs.dns_repair;
import core.repairs.interface_repair;
import core.repairs.routing_repair;

/// Convert DNSDiagnostics to JSON
JSONValue toJSON(DNSDiagnostics diag) @safe {
    JSONValue result = JSONValue.emptyObject;

    result["has_dns_servers"] = diag.hasDNSServers;
    result["can_resolve"] = diag.canResolve;

    JSONValue[] servers;
    foreach (server; diag.servers) {
        JSONValue s = JSONValue.emptyObject;
        s["address"] = server.address;
        s["port"] = server.port;
        s["reachable"] = server.reachable;
        if (!server.latencyMs.isNull) {
            s["latency_ms"] = server.latencyMs.get;
        }
        servers ~= s;
    }
    result["servers"] = JSONValue(servers);

    result["warnings"] = JSONValue(diag.warnings);
    result["recommendations"] = JSONValue(diag.recommendations);

    return result;
}

/// Convert InterfaceDiagnostics to JSON
JSONValue toJSON(InterfaceDiagnostics diag) @safe {
    JSONValue result = JSONValue.emptyObject;

    JSONValue[] interfaces;
    foreach (iface; diag.interfaces) {
        JSONValue i = JSONValue.emptyObject;
        i["name"] = iface.name;
        i["mac_address"] = iface.macAddress;
        i["ipv4_addresses"] = JSONValue(iface.ipv4Addresses);
        i["is_up"] = iface.isUp;
        i["has_carrier"] = iface.hasCarrier;
        i["rx_bytes"] = iface.rxBytes;
        i["tx_bytes"] = iface.txBytes;
        i["rx_packets"] = iface.rxPackets;
        i["tx_packets"] = iface.txPackets;
        interfaces ~= i;
    }
    result["interfaces"] = JSONValue(interfaces);

    result["up_interfaces"] = diag.upInterfaces.length;
    result["down_interfaces"] = diag.downInterfaces.length;
    result["no_carrier_interfaces"] = diag.noCarrierInterfaces.length;
    result["no_ip_interfaces"] = diag.noIPInterfaces.length;

    result["warnings"] = JSONValue(diag.warnings);
    result["recommendations"] = JSONValue(diag.recommendations);

    return result;
}

/// Convert RoutingDiagnostics to JSON
JSONValue toJSON(RoutingDiagnostics diag) @safe {
    JSONValue result = JSONValue.emptyObject;

    result["has_default_route"] = diag.hasDefaultRoute;
    result["can_reach_gateway"] = diag.canReachGateway;
    result["gateway_ip"] = diag.gatewayIP;

    JSONValue[] routes;
    foreach (route; diag.routes) {
        JSONValue r = JSONValue.emptyObject;
        r["destination"] = route.destination;
        r["gateway"] = route.gateway;
        r["interface"] = route.interfaceName;
        r["metric"] = route.metric;
        r["is_default"] = route.isDefault;
        routes ~= r;
    }
    result["routes"] = JSONValue(routes);

    JSONValue[] defaultRoutes;
    foreach (route; diag.defaultRoutes) {
        JSONValue r = JSONValue.emptyObject;
        r["gateway"] = route.gateway;
        r["interface"] = route.interfaceName;
        r["metric"] = route.metric;
        defaultRoutes ~= r;
    }
    result["default_routes"] = JSONValue(defaultRoutes);

    result["warnings"] = JSONValue(diag.warnings);
    result["recommendations"] = JSONValue(diag.recommendations);

    return result;
}

/// Convert ConnectivityDiagnostics to JSON
JSONValue toJSON(ConnectivityDiagnostics diag) @safe {
    JSONValue result = JSONValue.emptyObject;

    result["has_internet"] = diag.hasInternet;
    result["has_dns"] = diag.hasDNS;
    result["avg_latency_ms"] = diag.avgLatency;

    JSONValue[] tests;
    foreach (test; diag.tests) {
        JSONValue t = JSONValue.emptyObject;
        t["target"] = test.target;
        t["reachable"] = test.reachable;
        t["latency_ms"] = test.latencyMs;
        t["protocol"] = test.protocol;
        tests ~= t;
    }
    result["tests"] = JSONValue(tests);

    result["warnings"] = JSONValue(diag.warnings);
    result["recommendations"] = JSONValue(diag.recommendations);

    return result;
}

/// Convert DNSRepairResult to JSON
JSONValue toJSON(DNSRepairResult repair) @safe {
    JSONValue result = JSONValue.emptyObject;

    result["success"] = repair.success;
    result["backup_created"] = repair.backupCreated;
    result["backup_path"] = repair.backupPath;
    result["actions"] = JSONValue(repair.actions);
    result["errors"] = JSONValue(repair.errors);

    return result;
}

/// Convert InterfaceRepairResult to JSON
JSONValue toJSON(InterfaceRepairResult repair) @safe {
    JSONValue result = JSONValue.emptyObject;

    result["success"] = repair.success;
    result["actions"] = JSONValue(repair.actions);
    result["errors"] = JSONValue(repair.errors);

    JSONValue[] repaired;
    foreach (iface; repair.repairedInterfaces) {
        JSONValue i = JSONValue.emptyObject;
        i["name"] = iface.name;
        i["is_up"] = iface.isUp;
        i["has_carrier"] = iface.hasCarrier;
        i["ipv4_addresses"] = JSONValue(iface.ipv4Addresses);
        repaired ~= i;
    }
    result["repaired_interfaces"] = JSONValue(repaired);

    return result;
}

/// Convert RoutingRepairResult to JSON
JSONValue toJSON(RoutingRepairResult repair) @safe {
    JSONValue result = JSONValue.emptyObject;

    result["success"] = repair.success;
    result["actions"] = JSONValue(repair.actions);
    result["errors"] = JSONValue(repair.errors);

    JSONValue[] added;
    foreach (route; repair.addedRoutes) {
        JSONValue r = JSONValue.emptyObject;
        r["destination"] = route.destination;
        r["gateway"] = route.gateway;
        r["interface"] = route.interfaceName;
        r["metric"] = route.metric;
        added ~= r;
    }
    result["added_routes"] = JSONValue(added);

    JSONValue[] removed;
    foreach (route; repair.removedRoutes) {
        JSONValue r = JSONValue.emptyObject;
        r["destination"] = route.destination;
        r["gateway"] = route.gateway;
        r["interface"] = route.interfaceName;
        r["metric"] = route.metric;
        removed ~= r;
    }
    result["removed_routes"] = JSONValue(removed);

    return result;
}

/// Format complete diagnostics as JSON
string diagnosticsToJSON(
    DNSDiagnostics dnsDiag,
    RoutingDiagnostics routingDiag,
    ConnectivityDiagnostics connDiag,
    InterfaceDiagnostics ifaceDiag
) @safe {
    JSONValue result = JSONValue.emptyObject;

    result["version"] = "1.1.0-alpha";
    result["tool"] = "network-ambulance-d";
    result["dns"] = dnsDiag.toJSON();
    result["routing"] = routingDiag.toJSON();
    result["connectivity"] = connDiag.toJSON();
    result["interfaces"] = ifaceDiag.toJSON();

    return result.toPrettyString();
}

/// Format repair results as JSON
string repairToJSON(
    DNSRepairResult dnsRepair,
    InterfaceRepairResult ifaceRepair,
    RoutingRepairResult routingRepair
) @safe {
    JSONValue result = JSONValue.emptyObject;

    result["version"] = "1.1.0-alpha";
    result["tool"] = "network-ambulance-d";
    result["dns_repair"] = dnsRepair.toJSON();
    result["interface_repair"] = ifaceRepair.toJSON();
    result["routing_repair"] = routingRepair.toJSON();

    return result.toPrettyString();
}
