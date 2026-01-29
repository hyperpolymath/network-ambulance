// SPDX-License-Identifier: PMPL-1.0-or-later
/**
 * Linux platform implementation
 */
module platform.linux;

version(Linux):

import platform.iface;
import platform.types;
import std.process;
import std.string;
import std.array;
import std.algorithm;
import std.conv;
import std.file;
import std.path;
import std.typecons;

/// Linux-specific network operations
class LinuxPlatform : NetworkPlatform {

    override string getPlatformName() @safe nothrow pure {
        return "Linux";
    }

    override InterfaceInfo[] getInterfaces() @trusted {
        InterfaceInfo[] interfaces;

        // Parse /sys/class/net/ directory
        try {
            foreach (string ifname; dirEntries("/sys/class/net", SpanMode.shallow)) {
                string name = baseName(ifname);
                if (name == "lo") continue; // Skip loopback for now

                try {
                    interfaces ~= getInterface(name);
                } catch (Exception e) {
                    // Skip interfaces we can't read
                    continue;
                }
            }
        } catch (Exception e) {
            // /sys not available, fallback to ip command
            return getInterfacesViaIP();
        }

        return interfaces;
    }

    override InterfaceInfo getInterface(string name) @trusted {
        InterfaceInfo info;
        info.name = name;

        string sysPath = "/sys/class/net/" ~ name;

        // Read interface state
        try {
            info.isUp = readText(sysPath ~ "/operstate").strip == "up";
            info.hasCarrier = readText(sysPath ~ "/carrier").strip == "1";
        } catch (Exception) {
            info.isUp = false;
            info.hasCarrier = false;
        }

        // Read MAC address
        try {
            info.macAddress = readText(sysPath ~ "/address").strip;
        } catch (Exception) {
            info.macAddress = "";
        }

        // Read statistics
        try {
            info.rxBytes = readText(sysPath ~ "/statistics/rx_bytes").strip.to!ulong;
            info.txBytes = readText(sysPath ~ "/statistics/tx_bytes").strip.to!ulong;
            info.rxPackets = readText(sysPath ~ "/statistics/rx_packets").strip.to!ulong;
            info.txPackets = readText(sysPath ~ "/statistics/tx_packets").strip.to!ulong;
        } catch (Exception) {
            // Statistics not available
        }

        // Get IP addresses via ip command
        try {
            auto result = execute(["ip", "-o", "addr", "show", name]);
            if (result.status == 0) {
                foreach (line; result.output.splitLines) {
                    if (line.canFind("inet ")) {
                        auto parts = line.split();
                        foreach (i, part; parts) {
                            if (part == "inet" && i + 1 < parts.length) {
                                info.ipv4Addresses ~= parts[i + 1];
                            } else if (part == "inet6" && i + 1 < parts.length) {
                                info.ipv6Addresses ~= parts[i + 1];
                            }
                        }
                    }
                }
            }
        } catch (Exception) {
            // IP command failed
        }

        return info;
    }

    override bool bringInterfaceUp(string name) @trusted {
        try {
            auto result = execute(["ip", "link", "set", name, "up"]);
            return result.status == 0;
        } catch (Exception) {
            return false;
        }
    }

    override bool bringInterfaceDown(string name) @trusted {
        try {
            auto result = execute(["ip", "link", "set", name, "down"]);
            return result.status == 0;
        } catch (Exception) {
            return false;
        }
    }

    override bool renewDHCP(string interfaceName) @trusted {
        // Try dhclient first
        try {
            auto result = execute(["dhclient", "-r", interfaceName]);
            if (result.status == 0) {
                result = execute(["dhclient", interfaceName]);
                return result.status == 0;
            }
        } catch (Exception) {}

        // Try systemd-networkd
        try {
            auto result = execute(["networkctl", "renew", interfaceName]);
            return result.status == 0;
        } catch (Exception) {}

        return false;
    }

    override DNSServer[] getDNSServers() @trusted {
        DNSServer[] servers;

        // Read /etc/resolv.conf
        try {
            string resolvConf = readText("/etc/resolv.conf");
            foreach (line; resolvConf.splitLines) {
                line = line.strip;
                if (line.startsWith("nameserver ")) {
                    string addr = line[11..$].strip;
                    servers ~= DNSServer(addr);
                }
            }
        } catch (Exception) {}

        return servers;
    }

    override bool setDNSServers(DNSServer[] servers) @trusted {
        // This requires root, implement backup and write
        try {
            string content = "# Generated by Network Ambulance\n";
            foreach (server; servers) {
                content ~= "nameserver " ~ server.address ~ "\n";
            }

            // TODO: Backup original file first
            std.file.write("/etc/resolv.conf", content);
            return true;
        } catch (Exception) {
            return false;
        }
    }

    override Route[] getRoutes() @trusted {
        Route[] routes;

        try {
            auto result = execute(["ip", "-o", "route", "show"]);
            if (result.status != 0) return routes;

            foreach (line; result.output.splitLines) {
                auto parts = line.split();
                if (parts.length < 3) continue;

                Route route;

                if (parts[0] == "default") {
                    route.isDefault = true;
                    route.destination = "0.0.0.0/0";

                    // Parse: default via <gateway> dev <iface>
                    for (size_t i = 0; i < parts.length; i++) {
                        if (parts[i] == "via" && i + 1 < parts.length) {
                            route.gateway = parts[i + 1];
                        } else if (parts[i] == "dev" && i + 1 < parts.length) {
                            route.interfaceName = parts[i + 1];
                        } else if (parts[i] == "metric" && i + 1 < parts.length) {
                            route.metric = parts[i + 1].to!uint;
                        }
                    }
                } else {
                    route.destination = parts[0];
                    // Parse similar to default route
                }

                routes ~= route;
            }
        } catch (Exception) {}

        return routes;
    }

    override bool addDefaultRoute(string gateway, string interfaceName) @trusted {
        try {
            auto result = execute(["ip", "route", "add", "default", "via", gateway, "dev", interfaceName]);
            return result.status == 0;
        } catch (Exception) {
            return false;
        }
    }

    override bool deleteRoute(string destination) @trusted {
        try {
            auto result = execute(["ip", "route", "del", destination]);
            return result.status == 0;
        } catch (Exception) {
            return false;
        }
    }

    override bool pingIP(string ip, uint timeout = 5) @trusted {
        try {
            auto result = execute(["ping", "-c", "1", "-W", timeout.to!string, ip]);
            return result.status == 0;
        } catch (Exception) {
            return false;
        }
    }

    override bool testDNS(string hostname, string dnsServer) @trusted {
        try {
            auto result = execute(["dig", "+short", "+time=2", "@" ~ dnsServer, hostname]);
            return result.status == 0 && result.output.strip.length > 0;
        } catch (Exception) {
            return false;
        }
    }

    private InterfaceInfo[] getInterfacesViaIP() @trusted {
        InterfaceInfo[] interfaces;

        try {
            auto result = execute(["ip", "-o", "link", "show"]);
            if (result.status != 0) return interfaces;

            foreach (line; result.output.splitLines) {
                auto parts = line.split();
                if (parts.length < 2) continue;

                string name = parts[1].stripRight(":");
                if (name == "lo") continue;

                try {
                    interfaces ~= getInterface(name);
                } catch (Exception) {
                    continue;
                }
            }
        } catch (Exception) {}

        return interfaces;
    }
}
