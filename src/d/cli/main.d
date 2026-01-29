// SPDX-License-Identifier: PMPL-1.0-or-later
/**
 * Network Ambulance - D lang implementation
 * Main CLI entry point
 */
module cli.main;

import std.stdio;
import std.getopt;
import std.conv;
import platform;
import core.diagnostics.dns;
import core.diagnostics.interfaces;

/// CLI commands
enum Command {
    Diagnose,
    Status,
    Version,
    Help
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

/// Print help
void printHelp() {
    writeln("Network Ambulance - D lang implementation");
    writeln();
    writeln("Usage: network-ambulance-d <command> [options]");
    writeln();
    writeln("Commands:");
    writeln("  diagnose      Run full network diagnostics");
    writeln("  status        Quick connectivity status");
    writeln("  version       Show version information");
    writeln("  help          Show this help");
    writeln();
    writeln("Options:");
    writeln("  -v, --verbose    Verbose output");
    writeln("  -j, --json       JSON output format");
    writeln();
    writeln("Examples:");
    writeln("  network-ambulance-d diagnose");
    writeln("  network-ambulance-d diagnose --verbose");
    writeln("  network-ambulance-d status");
}
