# Building Network Ambulance Tauri GUI

## Prerequisites

### Required Tools
- **Rust** (1.70+): `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`
- **Deno** (1.40+): `curl -fsSL https://deno.land/install.sh | sh`
- **ReScript** (11.0+): Managed via Deno tasks
- **D Compiler** (for backend): See BUILD_D.md

### Platform-Specific Requirements

**Linux:**
```bash
# Fedora
sudo dnf install webkit2gtk4.1-devel openssl-devel curl wget file \
                 libappindicator-gtk3-devel librsvg2-devel

# Ubuntu/Debian
sudo apt install libwebkit2gtk-4.1-dev build-essential curl wget file \
                 libxdo-dev libssl-dev libayatana-appindicator3-dev librsvg2-dev
```

**macOS:**
```bash
# Xcode Command Line Tools
xcode-select --install

# Homebrew dependencies (if needed)
brew install openssl
```

**Windows:**
- Install Visual Studio 2022 with C++ tools
- Install WebView2: https://developer.microsoft.com/microsoft-edge/webview2/

## Development

### First-time setup:
```bash
# Install ReScript compiler
deno task rescript build

# Build D backend first
dub build --build=release
```

### Run in development mode:
```bash
# Start dev server (hot reload)
deno task tauri:dev
```

This will:
1. Start Vite dev server on localhost:5173
2. Compile ReScript in watch mode
3. Launch Tauri app with dev tools

### Build for production:
```bash
# Build optimized release
deno task tauri:build
```

Outputs:
- **Linux**: `src-tauri/target/release/bundle/deb/*.deb`
- **Linux**: `src-tauri/target/release/bundle/appimage/*.AppImage`
- **macOS**: `src-tauri/target/release/bundle/dmg/*.dmg`
- **Windows**: `src-tauri/target/release/bundle/nsis/*.exe`

## Cross-Platform Builds

### Windows (from Linux with cross-compilation):
```bash
rustup target add x86_64-pc-windows-msvc
cargo tauri build --target x86_64-pc-windows-msvc
```

### macOS (from macOS only):
```bash
# Universal binary (Intel + Apple Silicon)
rustup target add x86_64-apple-darwin aarch64-apple-darwin
cargo tauri build --target universal-apple-darwin
```

### Linux ARM (Raspberry Pi, etc.):
```bash
rustup target add aarch64-unknown-linux-gnu
cargo tauri build --target aarch64-unknown-linux-gnu
```

## Mobile Builds

### Android:
```bash
# Add Android targets
rustup target add aarch64-linux-android armv7-linux-androideabi

# Install Android SDK/NDK
# Set ANDROID_HOME and ANDROID_NDK_HOME

# Initialize Android project
cargo tauri android init

# Build APK
cargo tauri android build
```

### iOS (macOS only):
```bash
# Add iOS targets
rustup target add aarch64-apple-ios x86_64-apple-ios

# Initialize iOS project
cargo tauri ios init

# Build for iOS
cargo tauri ios build
```

## MINIX Support

**Tauri does not support MINIX** due to:
- Rust limited support on MINIX 3.x
- No WebView available
- Modern GUI frameworks require newer syscalls

**Fallback for MINIX:**
Use the D CLI or Ada TUI instead:
```bash
# On MINIX, use command-line tools
./bin/network-ambulance-d diagnose
./bin/network-ambulance-tui
```

See MINIX_BUILD.md for details on building D/Ada on MINIX.

## Project Structure

```
network-ambulance/
├── src/
│   └── rescript/          # ReScript frontend
│       ├── Main.res       # Entry point
│       ├── App.res        # Main app component
│       ├── Types.res      # Type definitions
│       └── components/    # UI components
├── src-tauri/
│   ├── src/
│   │   ├── main.rs        # Rust backend
│   │   ├── lib.rs         # Mobile entry points
│   │   └── build.rs       # Build script
│   ├── Cargo.toml         # Rust dependencies
│   └── tauri.conf.json    # Tauri configuration
├── public/                # Static assets
├── dist/                  # Build output
├── index.html             # HTML entry point
├── vite.config.js         # Vite bundler config
├── rescript.json          # ReScript config
└── deno.json              # Deno tasks and imports
```

## Development Commands

```bash
# ReScript compilation (watch mode)
deno task rescript build -w

# Vite dev server only
deno task dev

# Full Tauri dev (recommended)
deno task tauri:dev

# Build D backend
dub build --build=release

# Build Ada TUI
gprbuild -P network_ambulance_tui.gpr -XBUILD_MODE=release

# Format ReScript code
deno task format

# Lint Rust code
cd src-tauri && cargo clippy
```

## Debugging

### Enable Tauri DevTools:
- Development mode automatically opens DevTools
- Or press `Ctrl+Shift+I` / `Cmd+Option+I`

### View Tauri logs:
```bash
# Console logs from Rust
RUST_LOG=debug cargo tauri dev

# Full verbose logging
RUST_LOG=trace cargo tauri dev
```

### Debug ReScript:
- ReScript compiles to readable JS
- Check `src/rescript/*.res.js` for compiled output
- Use browser DevTools to debug

## Performance Optimization

### Reduce Bundle Size:
```bash
# Strip debug symbols
cargo tauri build --config '{"bundle":{"windows":{"webviewInstallMode":{"type":"embedBootstrapper"}}}}'

# Optimize ReScript output
deno task rescript build -release
```

### Profile Performance:
```bash
# Rust profiling
cargo tauri build --profile release-with-debug
samply record ./target/release/network-ambulance

# Frontend profiling
# Use Chrome DevTools Performance tab
```

## Troubleshooting

**Error: `webkit2gtk not found`**
- Install WebKitGTK: `sudo dnf install webkit2gtk4.1-devel`

**Error: `failed to run custom build command for 'tauri-build'`**
- Update Rust: `rustup update`
- Clean and rebuild: `cargo clean && cargo build`

**Error: `ReScript compilation failed`**
- Check rescript.json syntax
- Ensure `@rescript/core` is installed
- Run `deno task rescript clean` and retry

**Error: `D backend not found`**
- Build D backend first: `dub build --build=release`
- Ensure `bin/network-ambulance-d` exists

**Mobile build fails:**
- Verify Android SDK/NDK paths
- Check Xcode installation on macOS
- Ensure mobile targets are installed

## CI/CD

### GitHub Actions (example):
```yaml
name: Build Tauri App
on: [push]
jobs:
  build:
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest, windows-latest]
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      - uses: denoland/setup-deno@v1
      - uses: dtolnay/rust-toolchain@stable
      - name: Build D backend
        run: dub build --build=release
      - name: Build Tauri
        run: deno task tauri:build
```

## Platform Support Matrix

| Platform | Architecture | Tauri Support | D Backend | Status |
|----------|-------------|---------------|-----------|--------|
| Linux    | x86_64      | ✅ Full       | ✅ Yes    | ✅ Tested |
| Linux    | ARM64       | ✅ Full       | ✅ Yes    | 🔄 Partial |
| macOS    | Intel       | ✅ Full       | ✅ Yes    | ⚠️ Untested |
| macOS    | ARM (M1+)   | ✅ Full       | ✅ Yes    | ⚠️ Untested |
| Windows  | x86_64      | ✅ Full       | ⚠️ Limited | ⚠️ Untested |
| Android  | ARM64       | ✅ Tauri 2.0+ | ❌ CLI only | 🔄 In Progress |
| iOS      | ARM64       | ✅ Tauri 2.0+ | ❌ CLI only | 🔄 In Progress |
| MINIX    | x86         | ❌ No GUI     | ✅ Yes    | 📝 CLI/TUI only |

Legend:
- ✅ Full support
- ⚠️ Limited/untested
- 🔄 Partial/in progress
- ❌ Not supported
- 📝 Documentation provided
