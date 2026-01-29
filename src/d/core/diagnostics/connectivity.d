// SPDX-License-Identifier: PMPL-1.0-or-later
/**
 * Connectivity diagnostics
 */
module core.diagnostics.connectivity;

import platform;
import std.datetime.stopwatch;
import std.format;
import std.conv : to;

/// Connectivity test result
struct ConnectivityTest {
    string target;
    bool reachable;
    double latencyMs;
    string protocol;
}

/// Connectivity diagnostic results
struct ConnectivityDiagnostics {
    ConnectivityTest[] tests;
    bool hasInternet;
    bool hasDNS;
    double avgLatency;
    string[] warnings;
    string[] recommendations;
}

/// Run connectivity diagnostics
ConnectivityDiagnostics diagnoseConnectivity(NetworkPlatform platform) @safe {
    ConnectivityDiagnostics result;

    // Test 1: Ping Google DNS (no DNS required)
    {
        auto sw = StopWatch(AutoStart.yes);
        bool ok = platform.pingIP("8.8.8.8", 5);
        sw.stop();

        result.tests ~= ConnectivityTest(
            "8.8.8.8 (Google DNS)",
            ok,
            sw.peek.total!"msecs",
            "ICMP"
        );
    }

    // Test 2: Ping Cloudflare DNS
    {
        auto sw = StopWatch(AutoStart.yes);
        bool ok = platform.pingIP("1.1.1.1", 5);
        sw.stop();

        result.tests ~= ConnectivityTest(
            "1.1.1.1 (Cloudflare DNS)",
            ok,
            sw.peek.total!"msecs",
            "ICMP"
        );
    }

    // Test 3: DNS resolution
    {
        auto sw = StopWatch(AutoStart.yes);
        bool ok = platform.testDNS("google.com", "8.8.8.8");
        sw.stop();

        result.tests ~= ConnectivityTest(
            "google.com (DNS test)",
            ok,
            sw.peek.total!"msecs",
            "DNS"
        );

        result.hasDNS = ok;
    }

    // Test 4: DNS resolution alternative
    {
        auto sw = StopWatch(AutoStart.yes);
        bool ok = platform.testDNS("cloudflare.com", "1.1.1.1");
        sw.stop();

        result.tests ~= ConnectivityTest(
            "cloudflare.com (DNS test)",
            ok,
            sw.peek.total!"msecs",
            "DNS"
        );
    }

    // Determine overall internet status
    import std.algorithm : filter, map, sum, count, any;

    auto icmpTests = result.tests.filter!(t => t.protocol == "ICMP");
    result.hasInternet = any!(t => t.reachable)(icmpTests);

    if (result.hasInternet) {
        auto reachableTests = result.tests.filter!(t => t.reachable);
        if (reachableTests.count > 0) {
            result.avgLatency = reachableTests.map!(t => t.latencyMs).sum / reachableTests.count;
        }
    }

    // Generate warnings and recommendations
    if (!result.hasInternet) {
        result.warnings ~= "No internet connectivity detected";
        result.recommendations ~= "Check network cable/WiFi connection";
        result.recommendations ~= "Run 'network-ambulance-d diagnose' for detailed diagnostics";
    } else if (!result.hasDNS) {
        result.warnings ~= "Internet connectivity OK but DNS resolution failing";
        result.recommendations ~= "Fix DNS configuration (see DNS diagnostics)";
    } else if (result.avgLatency > 200) {
        result.warnings ~= format("High latency detected (%.0fms average)", result.avgLatency);
        result.recommendations ~= "Network is slow - consider running traffic-conditioner";
    }

    return result;
}
