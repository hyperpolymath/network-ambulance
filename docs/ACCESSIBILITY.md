# Accessibility

## Commitment to Accessibility

The Complete Linux Internet Repair Tool is committed to being accessible to all users, including those with disabilities. As a command-line tool, we follow terminal accessibility best practices.

## Current Accessibility Features

### Color and Visual

1. **Color Detection**
   - Automatic detection of terminal color capabilities
   - Graceful degradation when colors not supported
   - `--no-color` flag to disable all color output

2. **High Contrast**
   - Careful selection of ANSI colors for readability
   - Green (success), Yellow (warning), Red (error), Blue (info)
   - Works with both light and dark terminal backgrounds

3. **Screen Reader Compatible**
   - Plain text output that screen readers can parse
   - No ASCII art or complex formatting
   - Structured output with clear headers and sections

### Output Clarity

1. **Clear Status Indicators**
   - ✅ (success), ⚠️ (warning), ❌ (error), → (action)
   - Text equivalents: [✓], [WARN], [ERROR], [INFO]
   - Both visual and textual indicators provided

2. **Verbose Mode**
   - `--verbose` flag for detailed output
   - Explains what the tool is doing at each step
   - Helpful for users who need more context

3. **Quiet Mode**
   - `--quiet` flag for minimal output
   - Only errors are shown
   - Reduces cognitive load

### Interactive Mode

1. **Keyboard-Only Navigation**
   - Menu-driven interface
   - Number keys for selection
   - No mouse required

2. **Clear Prompts**
   - Unambiguous question text
   - Default options indicated
   - Confirmation for destructive actions

3. **Timeout-Free**
   - No time limits on user input
   - Users can take their time reading options
   - Pauses wait indefinitely for user response

## Accessibility Guidelines Followed

### WCAG 2.1 Principles (Adapted for CLI)

1. **Perceivable**
   - ✅ Text alternatives for visual indicators
   - ✅ Color is not the only means of conveying information
   - ✅ Content can be presented in different ways

2. **Operable**
   - ✅ All functionality available from keyboard
   - ✅ No timing constraints on user input
   - ✅ Clear navigation through menus

3. **Understandable**
   - ✅ Readable error messages
   - ✅ Predictable operation
   - ✅ Input assistance (hints and examples)

4. **Robust**
   - ✅ Works with standard terminal emulators
   - ✅ Compatible with screen readers (orca, NVDA via SSH)
   - ✅ POSIX-compliant where possible

## Screen Reader Support

### Tested With

- **Orca** (Linux): Works with terminal output
- **NVDA** (Windows via WSL): Compatible
- **VoiceOver** (macOS): Compatible with Terminal.app

### Best Practices for Screen Reader Users

```bash
# Use verbose mode for more context
network-repair --verbose diagnose

# Disable colors for cleaner screen reader output
network-repair --no-color diagnose

# Save output to file for review
network-repair diagnose > /tmp/diag.txt 2>&1
less /tmp/diag.txt
```

## Visual Impairment Considerations

### Low Vision

1. **Large Text Terminals**
   - Tool respects terminal font size settings
   - No fixed-width assumptions
   - Works with zoomed terminals

2. **High Contrast Themes**
   - Works with high-contrast terminal themes
   - ANSI colors adapt to theme
   - No hardcoded color codes

### Color Blindness

1. **Not Relying on Color Alone**
   - Status indicated by text symbols: ✓, ✗, ⚠
   - Text labels: [INFO], [WARN], [ERROR], [SUCCESS]
   - Position and structure convey meaning

2. **Protanopia/Deuteranopia (Red-Green)**
   - Errors use text labels, not just red color
   - Success uses text labels, not just green color
   - Icons supplement color

3. **Tritanopia (Blue-Yellow)**
   - Info messages use text labels
   - Warnings use text labels

## Cognitive Accessibility

### Clear Language

1. **Plain Language**
   - Avoid jargon where possible
   - Explain technical terms when used
   - Short, clear sentences

2. **Consistent Terminology**
   - Same terms for same concepts
   - No synonyms for technical terms
   - Glossary in documentation

3. **Progressive Disclosure**
   - Basic mode: Simple output
   - Verbose mode: Detailed explanation
   - Help text available at any time

### Error Messages

1. **Actionable Errors**
   - What went wrong
   - Why it happened
   - How to fix it

Example:
```
❌ [ERROR] No default route found!
   This means your computer doesn't know how to reach the internet.
   Run: sudo network-repair repair-routing
```

### Predictable Behavior

1. **Dry-Run Mode**
   - Preview changes before applying
   - Reduces anxiety about mistakes
   - `--dry-run` flag available

2. **Reversibility**
   - All changes are backed up
   - Backups stored in `~/.network-repair-backups/`
   - Easy to undo mistakes

## Physical Accessibility

### Motor Impairments

1. **Minimal Typing**
   - Single-letter menu choices (y/n, 1-6)
   - Tab completion for file paths
   - Default options reduce typing

2. **Error Tolerance**
   - Forgiving input parsing
   - Clear error messages for invalid input
   - No case sensitivity for y/n prompts

3. **Alternative Input Methods**
   - Works with voice input (Dragon, speech recognition)
   - Compatible with adaptive keyboards
   - No mouse required

## Auditory Accessibility

### No Audio Requirements

- All information presented visually as text
- No audio cues or warnings
- No sound effects
- Silent operation

## Language and Localization

### Current Status

- **Primary Language**: English (US)
- **Future Plans**: i18n support (see docs/I18N.md)

### Clear English

- Simple vocabulary
- Short sentences
- Active voice preferred
- Technical terms explained

## Testing

### Accessibility Testing Checklist

- [ ] Works with `--no-color` flag
- [ ] Output readable with screen reader
- [ ] Menu navigation keyboard-only
- [ ] No time limits on input
- [ ] Error messages actionable
- [ ] Works in high-contrast mode
- [ ] Tab completion functional
- [ ] Help text comprehensive

### Test Commands

```bash
# Test without colors
network-repair --no-color diagnose

# Test with screen reader
orca &
network-repair diagnose

# Test verbose output
network-repair --verbose diagnose | less

# Test interactive mode
sudo network-repair interactive
```

## Known Limitations

1. **Terminal-Only**
   - No GUI alternative (planned for future)
   - Requires terminal emulator
   - Command-line knowledge helpful

2. **English-Only**
   - Currently only English (US)
   - i18n planned for future versions
   - See docs/I18N.md for roadmap

3. **Root Required for Repairs**
   - Many operations need sudo/root
   - Diagnostics work without root
   - Clear prompts when sudo needed

## Reporting Accessibility Issues

If you encounter accessibility barriers:

1. **Open an Issue**
   - Tag with `accessibility` label
   - Describe the barrier
   - Include your setup (OS, terminal, assistive tech)

2. **Suggest Improvements**
   - We welcome accessibility enhancement PRs
   - See CONTRIBUTING.md
   - Ask questions first

3. **Contact**
   - Email: accessibility@example.com
   - GitHub: Open issue with [ACCESSIBILITY] tag

## Accessibility Roadmap

### Short Term (v1.1)

- [ ] Improve screen reader testing
- [ ] Add more text-only output options
- [ ] Enhanced `--no-color` mode
- [ ] Accessibility testing in CI

### Medium Term (v1.2-1.3)

- [ ] i18n support (see I18N.md)
- [ ] GUI mode (Electron or web-based)
- [ ] Better error message formatting
- [ ] Audio output option (TTS)

### Long Term (v2.0+)

- [ ] Full WCAG 2.1 AA compliance audit
- [ ] Multiple UI modes (CLI, TUI, GUI)
- [ ] Braille display support
- [ ] Switch access support

## Resources

### Standards

- [WCAG 2.1](https://www.w3.org/WAI/WCAG21/quickref/)
- [Section 508](https://www.section508.gov/)
- [EN 301 549](https://www.etsi.org/deliver/etsi_en/301500_301599/301549/03.02.01_60/en_301549v030201p.pdf)

### Tools

- [Pa11y](https://pa11y.org/) - Accessibility testing
- [axe DevTools](https://www.deque.com/axe/) - Accessibility checker
- [NVDA](https://www.nvaccess.org/) - Windows screen reader
- [Orca](https://help.gnome.org/users/orca/stable/) - Linux screen reader

### Community

- [A11y Project](https://www.a11yproject.com/)
- [WebAIM](https://webaim.org/)
- [Inclusive Design Principles](https://inclusivedesignprinciples.org/)

## Acknowledgments

We thank the accessibility community for ongoing guidance and feedback. Special thanks to users who test with assistive technology and report issues.

---

**Last Updated**: 2025-01-22
**Version**: 1.0
**Contact**: accessibility@example.com
