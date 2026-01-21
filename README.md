# Wyatt

A tiny macOS menu bar app that rounds up all your windows and brings them to your main screen.

Perfect for multi-monitor setups where one screen is shared with another computer—when that screen isn't showing your Mac, windows can get stranded there. One click and Wyatt brings 'em home.

## Usage

- **Left click** the lasso icon → moves all off-screen windows to screen #1
- **Right click** → menu with "Round 'em up!" and "Quit"
- **⌘⌥R** → global hotkey

Windows keep their position but get clamped to fit within the main screen.

## Requirements

- macOS 13+
- Accessibility permissions (prompted on first launch)

## Build & Install

```bash
make install
```

This builds a proper `.app` bundle and installs it to `/Applications`.

Then add Wyatt to Login Items in System Settings to launch at startup.

## Other commands

```bash
make build      # build the .app bundle locally
make uninstall  # remove from /Applications
make clean      # clean build artifacts
```

## License

MIT
