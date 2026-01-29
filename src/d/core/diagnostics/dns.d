// SPDX-License-Identifier: PMPL-1.0-or-later
/**
 * DNS diagnostics
 */
module core.diagnostics.dns;

import platform;
import std.datetime.stopwatch;
import std.algorithm;
import std.array;
import std.conv : to;
import std.format : format;

/// DNS diagnostic results
struct DNSDiagnostics {
    bool hasDNSServers;
    DNSServer[] servers;
    bool canResolve;
    string[] warnings;
    string[] recommendations;
}

/// Run DNS diagnostics
DNSDiagnostics diagnoseDNS(NetworkPlatform platform) @safe {
    DNSDiagnostics result;

    // Get configured DNS servers
    result.servers = platform.getDNSServers();
    result.hasDNSServers = result.servers.length > 0;

    if (!result.hasDNSServers) {
        result.warnings ~= "No DNS servers configured in /etc/resolv.conf";
        result.recommendations ~= "Add DNS servers (8.8.8.8, 1.1.1.1, 9.9.9.9)";
        return result;
    }

    // Test each DNS server
    foreach (ref server; result.servers) {
        auto sw = StopWatch(AutoStart.yes);
        server.reachable = platform.testDNS("google.com", server.address);
        sw.stop();

        if (server.reachable) {
            server.latencyMs = sw.peek.total!"msecs";
        }
    }

    // Check if at least one server works
    result.canResolve = result.servers.any!(s => s.reachable);

    if (!result.canResolve) {
        result.warnings ~= "No working DNS servers found";
        result.recommendations ~= "Switch to public DNS (8.8.8.8, 1.1.1.1)";
    } else {
        // Check for slow DNS
        auto workingServers = result.servers.filter!(s => s.reachable);
        if (!workingServers.empty) {
            auto avgLatency = workingServers.map!(s => s.latencyMs.get).sum / workingServers.count;
            if (avgLatency > 100) {
                result.warnings ~= format("DNS resolution is slow (avg %.0fms)", avgLatency);
                result.recommendations ~= "Consider using faster DNS servers";
            }
        }
    }

    return result;
}
