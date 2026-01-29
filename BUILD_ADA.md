# Building Network Ambulance Ada/SPARK TUI

## Prerequisites

### Install GNAT and SPARK

**Fedora:**
```bash
sudo dnf install gcc-gnat gprbuild gnat-llvm gnatprove
```

**Ubuntu/Debian:**
```bash
sudo apt install gnat gprbuild gnatprove
```

**Arch:**
```bash
sudo pacman -S gcc-ada gprbuild spark
```

**Or use Alire (Ada package manager):**
```bash
curl -LO https://github.com/alire-project/alire/releases/latest/download/alr-x86_64-linux.zip
unzip alr-x86_64-linux.zip
sudo mv bin/alr /usr/local/bin/
alr toolchain --select
```

## Building

### Debug build (default):
```bash
gprbuild -P network_ambulance_tui.gpr -XBUILD_MODE=debug
```

### Release build (optimized):
```bash
gprbuild -P network_ambulance_tui.gpr -XBUILD_MODE=release
```

### Prove mode (SPARK verification):
```bash
gprbuild -P network_ambulance_tui.gpr -XBUILD_MODE=prove
gnatprove -P network_ambulance_tui.gpr --level=2
```

## Running

```bash
# After building, binary is in bin/
./bin/network_ambulance_tui

# Or with Alire:
alr run
```

## SPARK Verification

The TUI includes formally verified state machine logic in `network_state.ads/adb`.

### Run SPARK proofs:
```bash
gnatprove -P network_ambulance_tui.gpr --level=2 --prover=cvc5,z3
```

### Proof levels:
- `--level=0`: Fast, basic checks
- `--level=1`: Standard checks
- `--level=2`: More thorough (recommended)
- `--level=3`: Maximum effort
- `--level=4`: Ultra paranoid (slow)

### View proof results:
```bash
gnatprove -P network_ambulance_tui.gpr --output=brief
```

## Features

### SPARK Verified Components
- **State Machine** (`network_state.ads/adb`):
  - Formally proven state transitions
  - Preconditions and postconditions on all operations
  - Proof that repair attempts never exceed maximum
  - Proof that terminal states are correctly identified

### TUI Features
- **Dashboard View**: Status overview with color-coded indicators
- **Diagnostics View**: Detailed network diagnostic results
- **Repairs View**: Available repair actions
- **Help View**: Keyboard commands and about info

### Keyboard Commands
- `d` - Run diagnostics
- `r` - Attempt repair
- `1` - Dashboard view
- `2` - Diagnostics view
- `3` - Repairs view
- `h` - Help
- `q` - Quit

## Integration with D Backend

The Ada TUI can call the D backend for real diagnostics:

```bash
# Run D diagnostics and parse JSON
./bin/network-ambulance-d diagnose --json | jq

# Run D repairs and parse JSON
sudo ./bin/network-ambulance-d repair all --json | jq
```

The TUI currently simulates diagnostics. To integrate with real backend:
1. Use `Ada.Processes` (Ada 2022) to spawn `network-ambulance-d`
2. Parse JSON output using a JSON library (e.g., `gnatcoll-json`)
3. Update `Context_Type` with real diagnostic data

## Project Structure

```
src/ada/
├── core/
│   ├── network_state.ads     # SPARK state machine spec
│   └── network_state.adb     # SPARK state machine impl
└── tui/
    ├── tui_display.ads       # TUI display interface
    ├── tui_display.adb       # TUI display impl
    └── network_ambulance_tui.adb  # Main program
```

## Troubleshooting

**Error: `gnatprove: command not found`**
- Install SPARK tools: `sudo dnf install gnatprove`

**Error: `gprbuild: invalid value for -XBUILD_MODE`**
- Valid values: `debug`, `release`, `prove`

**Error: Cannot prove all checks**
- Some properties may require manual proof or additional contracts
- Use `--prover=cvc5,z3,altergo` for multiple provers
- Increase timeout: `--timeout=60`

**SPARK errors in terminal I/O:**
- `TUI_Display` is marked `SPARK_Mode => Off` because terminal I/O is not provable
- Only `Network_State` is formally verified

## Development

### Add new SPARK contracts:
```ada
procedure My_Procedure (X : in out Integer)
with
   Pre  => X >= 0,
   Post => X > X'Old and X < 100;
```

### Run SPARK flow analysis:
```bash
gnatprove -P network_ambulance_tui.gpr --mode=flow
```

### Generate counterexamples for failed proofs:
```bash
gnatprove -P network_ambulance_tui.gpr --counterexamples=on
```

## Safety Properties Proven

The SPARK state machine proves:
1. ✓ State transitions are always valid
2. ✓ Repair attempts never exceed `Max_Repair_Attempts`
3. ✓ Terminal states are correctly identified
4. ✓ Previous state is always preserved
5. ✓ Reset correctly reinitializes all fields
6. ✓ No runtime errors (no exceptions, no overflows)

## Future Enhancements

- [ ] Real integration with D backend via `Ada.Processes`
- [ ] JSON parsing for diagnostic results
- [ ] ncurses-based UI with real terminal control
- [ ] Mouse support
- [ ] Configuration file support
- [ ] Logging to file
- [ ] Network interface selection
