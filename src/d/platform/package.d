// SPDX-License-Identifier: PMPL-1.0-or-later
/**
 * Platform Abstraction Layer for Network Ambulance
 *
 * Provides cross-platform interfaces for network operations
 */
module platform;

public import platform.types;
public import platform.iface;

version(Linux) {
    public import platform.linux;
    alias PlatformImpl = LinuxPlatform;
} else version(OSX) {
    public import platform.darwin;
    alias PlatformImpl = DarwinPlatform;
} else version(Windows) {
    public import platform.windows;
    alias PlatformImpl = WindowsPlatform;
} else version(BSD) {
    public import platform.bsd;
    alias PlatformImpl = BSDPlatform;
} else {
    static assert(0, "Unsupported platform");
}

/// Get platform-specific implementation
PlatformImpl getPlatform() @safe {
    return new PlatformImpl();
}
