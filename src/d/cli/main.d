// SPDX-License-Identifier: PMPL-1.0-or-later
/**
 * Network Ambulance - D lang implementation
 * Main CLI entry point
 */
module cli.main;

import std.stdio;
import std.getopt;
import std.conv;
import std.format;
import platform;
import core.diagnostics.dns;
import core.diagnostics.interfaces;
import core.diagnostics.routing;
import core.diagnostics.connectivity;
import core.repairs.dns_repair;
import core.repairs.interface_repair;
import core.repairs.routing_repair;

/// CLI commands
enum Command {
    Diagnose,
    Repair,
    Status,
    Version,
    Help
}

/// Repair targets
enum RepairTarget {
    DNS,
    Interface,
    Routing,
    All
}

/// Main entry point
int main(string[] args) {
    Command command = Command.Help;
    bool verbose = false;
    bool jsonOutput = false;

    try {
        auto helpInfo = getopt(args,
            "verbose|v", "Verbose output", &verbose,
            "json|j", "JSON output format", &jsonOutput
        );

        if (helpInfo.helpWanted || args.length < 2) {
            printHelp();
            return 0;
        }

        // Parse command
        string cmdStr = args[1];
        switch (cmdStr) {
            case "diagnose":
                command = Command.Diagnose;
                break;
            case "repair":
                command = Command.Repair;
                break;
            case "status":
                command = Command.Status;
                break;
            case "version":
                command = Command.Version;
                break;
            case "help":
                command = Command.Help;
                break;
            default:
                writeln("Unknown command: ", cmdStr);
                writeln("Run 'network-ambulance-d help' for usage");
                return 1;
        }

        // Execute command
        final switch (command) {
            case Command.Diagnose:
                return runDiagnose(verbose);
            case Command.Repair:
                // Parse repair target
                if (args.length < 3) {
                    writeln("Error: repair command requires a target");
                    writeln("Usage: network-ambulance-d repair <dns|interface|routing|all>");
                    return 1;
                }
                return runRepair(args[2], verbose);
            case Command.Status:
                return runStatus();
            case Command.Version:
                return runVersion();
            case Command.Help:
                printHelp();
                return 0;
        }

    } catch (Exception e) {
        writeln("Error: ", e.msg);
        return 1;
    }
}

/// Run full diagnostics
int runDiagnose(bool verbose) {
    writeln("Network Ambulance - D lang prototype");
    writeln("=====================================\n");

    auto platform = getPlatform();
    writeln("Platform: ", platform.getPlatformName(), "\n");

    // DNS Diagnostics
    writeln("=== DNS Diagnostics ===");
    auto dnsDiag = diagnoseDNS(platform);

    if (dnsDiag.hasDNSServers) {
        writeln("✓ DNS servers configured: ", dnsDiag.servers.length);
        foreach (server; dnsDiag.servers) {
            write("  - ", server.address);
            if (server.reachable) {
                writeln(" [REACHABLE, ", server.latencyMs.get.to!long, "ms]");
            } else {
                writeln(" [UNREACHABLE]");
            }
        }
    } else {
        writeln("✗ No DNS servers configured");
    }

    if (dnsDiag.canResolve) {
        writeln("✓ DNS resolution working");
    } else {
        writeln("✗ DNS resolution failing");
    }

    if (dnsDiag.warnings.length > 0) {
        writeln("\nWarnings:");
        foreach (warning; dnsDiag.warnings) {
            writeln("  ⚠ ", warning);
        }
    }

    if (dnsDiag.recommendations.length > 0) {
        writeln("\nRecommendations:");
        foreach (rec; dnsDiag.recommendations) {
            writeln("  → ", rec);
        }
    }

    writeln();

    // Routing Diagnostics
    writeln("=== Routing Diagnostics ===");
    auto routeDiag = diagnoseRouting(platform);

    if (routeDiag.hasDefaultRoute) {
        writeln("✓ Default route configured: ", routeDiag.defaultRoutes.length);
        foreach (route; routeDiag.defaultRoutes) {
            writeln("  - via ", route.gateway, " dev ", route.interfaceName,
                   " (metric: ", route.metric, ")");
        }
    } else {
        writeln("✗ No default route configured");
    }

    if (routeDiag.canReachGateway) {
        writeln("✓ Gateway ", routeDiag.gatewayIP, " is reachable");
    } else if (routeDiag.gatewayIP.length > 0) {
        writeln("✗ Cannot reach gateway ", routeDiag.gatewayIP);
    }

    if (verbose) {
        writeln("\nAll routes:");
        foreach (route; routeDiag.routes) {
            writefln("  %s via %s dev %s (metric: %d)",
                    route.destination, route.gateway, route.interfaceName, route.metric);
        }
    }

    if (routeDiag.warnings.length > 0) {
        writeln("\nWarnings:");
        foreach (warning; routeDiag.warnings) {
            writeln("  ⚠ ", warning);
        }
    }

    if (routeDiag.recommendations.length > 0) {
        writeln("\nRecommendations:");
        foreach (rec; routeDiag.recommendations) {
            writeln("  → ", rec);
        }
    }

    writeln();

    // Connectivity Diagnostics
    writeln("=== Connectivity Diagnostics ===");
    auto connDiag = diagnoseConnectivity(platform);

    foreach (test; connDiag.tests) {
        string status = test.reachable ? "✓" : "✗";
        writefln("%s %s [%s, %.0fms]", status, test.target, test.protocol, test.latencyMs);
    }

    if (connDiag.hasInternet) {
        writefln("\n✓ Internet connectivity: OK (avg latency: %.0fms)", connDiag.avgLatency);
    } else {
        writeln("\n✗ No internet connectivity");
    }

    if (connDiag.hasDNS) {
        writeln("✓ DNS resolution: OK");
    } else {
        writeln("✗ DNS resolution: FAILED");
    }

    if (connDiag.warnings.length > 0) {
        writeln("\nWarnings:");
        foreach (warning; connDiag.warnings) {
            writeln("  ⚠ ", warning);
        }
    }

    if (connDiag.recommendations.length > 0) {
        writeln("\nRecommendations:");
        foreach (rec; connDiag.recommendations) {
            writeln("  → ", rec);
        }
    }

    writeln();

    // Interface Diagnostics
    writeln("=== Interface Diagnostics ===");
    auto ifaceDiag = diagnoseInterfaces(platform);

    writeln("Total interfaces: ", ifaceDiag.interfaces.length);
    writeln("UP interfaces: ", ifaceDiag.upInterfaces.length);
    writeln("DOWN interfaces: ", ifaceDiag.downInterfaces.length);
    writeln();

    foreach (iface; ifaceDiag.interfaces) {
        string status = iface.isUp ? "UP" : "DOWN";
        string carrier = iface.hasCarrier ? "CARRIER" : "NO-CARRIER";

        writeln(iface.name, ": ", status, ", ", carrier);

        if (verbose) {
            writeln("  MAC: ", iface.macAddress);
            if (iface.ipv4Addresses.length > 0) {
                writeln("  IPv4: ", iface.ipv4Addresses);
            } else {
                writeln("  IPv4: None");
            }
            writeln("  RX: ", iface.rxPackets, " packets, ", iface.rxBytes, " bytes");
            writeln("  TX: ", iface.txPackets, " packets, ", iface.txBytes, " bytes");
        }
    }

    if (ifaceDiag.warnings.length > 0) {
        writeln("\nWarnings:");
        foreach (warning; ifaceDiag.warnings) {
            writeln("  ⚠ ", warning);
        }
    }

    if (ifaceDiag.recommendations.length > 0) {
        writeln("\nRecommendations:");
        foreach (rec; ifaceDiag.recommendations) {
            writeln("  → ", rec);
        }
    }

    return 0;
}

/// Run quick status check
int runStatus() {
    auto platform = getPlatform();

    // Quick connectivity test
    writeln("Connectivity: ", platform.pingIP("8.8.8.8", 2) ? "OK" : "FAILED");
    writeln("DNS: ", platform.testDNS("google.com", "8.8.8.8") ? "OK" : "FAILED");

    return 0;
}

/// Print version
int runVersion() {
    writeln("Network Ambulance D prototype v1.1.0-alpha");
    writeln("Platform: ", getPlatform().getPlatformName());
    return 0;
}

/// Run repair procedure
int runRepair(string target, bool verbose) {
    version(Posix) {
        import core.sys.posix.unistd : getuid;
    }

    // Check for root privileges
    version(Posix) {
        if (getuid() != 0) {
            writeln("Error: Repair operations require root privileges");
            writeln("Please run with sudo: sudo network-ambulance-d repair ", target);
            return 1;
        }
    }

    auto platform = getPlatform();
    RepairTarget repairTarget;

    // Parse repair target
    switch (target) {
        case "dns":
            repairTarget = RepairTarget.DNS;
            break;
        case "interface":
            repairTarget = RepairTarget.Interface;
            break;
        case "routing":
            repairTarget = RepairTarget.Routing;
            break;
        case "all":
            repairTarget = RepairTarget.All;
            break;
        default:
            writeln("Unknown repair target: ", target);
            writeln("Valid targets: dns, interface, routing, all");
            return 1;
    }

    writeln("Network Ambulance - Repair Mode");
    writeln("================================\n");

    bool anyRepaired = false;

    // DNS repair
    if (repairTarget == RepairTarget.DNS || repairTarget == RepairTarget.All) {
        writeln("=== DNS Repair ===");

        auto dnsDiag = diagnoseDNS(platform);
        auto dnsResult = repairDNS(platform, dnsDiag);

        if (dnsResult.backupCreated) {
            writeln("✓ Backup created: ", dnsResult.backupPath);
        }

        foreach (action; dnsResult.actions) {
            writeln("  ", action);
        }

        foreach (error; dnsResult.errors) {
            writeln("  ✗ ", error);
        }

        if (dnsResult.success) {
            writeln("✓ DNS repair completed successfully\n");
            anyRepaired = true;
        } else {
            writeln("✗ DNS repair failed\n");
        }
    }

    // Interface repair
    if (repairTarget == RepairTarget.Interface || repairTarget == RepairTarget.All) {
        writeln("=== Interface Repair ===");

        auto ifaceDiag = diagnoseInterfaces(platform);
        auto ifaceResult = repairInterfaces(platform, ifaceDiag);

        foreach (action; ifaceResult.actions) {
            writeln("  ", action);
        }

        foreach (error; ifaceResult.errors) {
            writeln("  ✗ ", error);
        }

        if (ifaceResult.success) {
            if (ifaceResult.repairedInterfaces.length > 0) {
                writeln("\nRepaired interfaces:");
                foreach (iface; ifaceResult.repairedInterfaces) {
                    writefln("  %s: %s, IP: %s",
                            iface.name,
                            iface.isUp ? "UP" : "DOWN",
                            iface.ipv4Addresses.length > 0 ? iface.ipv4Addresses[0] : "None");
                }
            }
            writeln("✓ Interface repair completed\n");
            anyRepaired = true;
        } else {
            writeln("✗ Interface repair failed\n");
        }
    }

    // Routing repair
    if (repairTarget == RepairTarget.Routing || repairTarget == RepairTarget.All) {
        writeln("=== Routing Repair ===");

        auto routeDiag = diagnoseRouting(platform);
        auto routeResult = repairRouting(platform, routeDiag);

        foreach (action; routeResult.actions) {
            writeln("  ", action);
        }

        foreach (error; routeResult.errors) {
            writeln("  ✗ ", error);
        }

        if (routeResult.addedRoutes.length > 0) {
            writeln("\nAdded routes:");
            foreach (route; routeResult.addedRoutes) {
                writefln("  %s via %s dev %s",
                        route.destination, route.gateway, route.interfaceName);
            }
        }

        if (routeResult.removedRoutes.length > 0) {
            writeln("\nRemoved routes:");
            foreach (route; routeResult.removedRoutes) {
                writefln("  %s via %s dev %s",
                        route.destination, route.gateway, route.interfaceName);
            }
        }

        if (routeResult.success) {
            writeln("✓ Routing repair completed\n");
            anyRepaired = true;
        } else {
            writeln("✗ Routing repair failed\n");
        }
    }

    return anyRepaired ? 0 : 1;
}

/// Print help
void printHelp() {
    writeln("Network Ambulance - D lang implementation");
    writeln();
    writeln("Usage: network-ambulance-d <command> [options]");
    writeln();
    writeln("Commands:");
    writeln("  diagnose      Run full network diagnostics");
    writeln("  repair        Repair network issues (requires sudo)");
    writeln("  status        Quick connectivity status");
    writeln("  version       Show version information");
    writeln("  help          Show this help");
    writeln();
    writeln("Repair Targets:");
    writeln("  dns           Fix DNS configuration");
    writeln("  interface     Fix network interface issues");
    writeln("  routing       Fix routing table issues");
    writeln("  all           Repair all detected issues");
    writeln();
    writeln("Options:");
    writeln("  -v, --verbose    Verbose output");
    writeln("  -j, --json       JSON output format");
    writeln();
    writeln("Examples:");
    writeln("  network-ambulance-d diagnose");
    writeln("  network-ambulance-d diagnose --verbose");
    writeln("  sudo network-ambulance-d repair dns");
    writeln("  sudo network-ambulance-d repair all");
    writeln("  network-ambulance-d status");
}
