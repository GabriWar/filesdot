# Hyprland Configuration Guide

This README contains all the keybindings and configuration details for my Hyprland setup.

## Environment Variables

The configuration sets various environment variables for NVIDIA compatibility, application defaults, and theme settings:

- NVIDIA compatibility: `LIBVA_DRIVER_NAME`, `__GLX_VENDOR_LIBRARY_NAME`, etc.
- Default applications: `TERMINAL=ghostty`, `BROWSER=thorium-browser`, `EDITOR=nvim`
- Theme settings: `HYPRCURSOR_THEME=Bibata-Modern-Ice`, `HYPRCURSOR_SIZE=20`

## Keybindings

### General

| Keybinding | Action |
|------------|--------|
| `Super + Shift + R` | Reload Hyprland configuration |
| `Super + E` | Open terminal (ghostty) |
| `Super + Q` | Kill active window |
| `Super + Shift + Q` | Force kill active window |
| `Super + Delete` | Power menu |
| `Super + Shift + Delete` | Exit Hyprland |
| `Super + Alt + Delete` | Force kill Hyprland |
| `Super + D` | Open file manager (krusader) |
| `Super + Alt + D` | Open Dolphin |
| `Super + V` | Toggle floating window |
| `Super + R` | Open application launcher (rofi) |
| `Super + Alt + R` | Open window switcher |
| `Super + Shift + T` | Open full rofi launcher |
| `Super + Ctrl + R` | Open rofi desktop menu |
| `Super + P` | Toggle pseudo mode |
| `Super + -` | Toggle split |
| `Super + W` | Open browser (thorium) |
| `Super + Shift + W` | Open browser in incognito mode |
| `Super + B` | Toggle waybar visibility |
| `Super + Shift + B` | Restart waybar |
| `Super + F` | Toggle fullscreen |
| `Super + C` | Pin window |
| `Super + X` | Change wallpaper |
| `Super + Space` | Toggle between keyboard layouts (BR/US) |

### Clipboard & Screenshots

| Keybinding | Action |
|------------|--------|
| `Super + Shift + V` | Open clipboard manager |
| `Super + Ctrl + V` | Restart clipboard service |
| `Super + Shift + Print` | Screenshot selection |
| `Super + Print` | Screenshot full screen |
| `Super + Ctrl + Print` | OCR selected area |
| `Super + Alt + Print` | Screen recording |
| `Super + F12` | Save replay |
| `Super + F11` | Toggle replay |

### Window Management

| Keybinding | Action |
|------------|--------|
| `Super + h/j/k/l` | Move focus left/down/up/right |
| `Super + Shift + Ctrl + h/j/k/l` | Move window left/down/up/right |
| `Super + Shift + h/j/k/l` | Resize window |
| `Super + T` | Toggle split mode |
| `Super + Alt + N` | Show window switcher (hyprswitch) |
| `Super + M + Mouse` | Move window with mouse |
| `Super + N + Mouse` | Resize window with mouse |

### Workspace Navigation

| Keybinding | Action |
|------------|--------|
| `Super + 1-0` | Switch to workspace 1-10 |
| `Super + TAB` | Switch to previous workspace |
| `Super + Alt + L/H` | Switch to next/previous workspace |
| `Super + Shift + 1-0` | Move window to workspace 1-10 |
| `Super + Alt + 1-0` | Move window to workspace silently |
| `Super + Ctrl + K/J` | Focus next/previous monitor |
| `Super + Mouse Wheel Up/Down` | Switch to next/previous workspace |

### Special Workspaces

| Keybinding | Action |
|------------|--------|
| `Super + S` | Toggle special workspace (magic) |
| `Super + Shift + S` | Move to special workspace (magic) |
| `Super + A` | Toggle ChatGPT workspace |
| `Super + Shift + A` | Toggle Gemini workspace |
| `Super + Z` | Toggle WhatsApp workspace |
| `Super + Shift + N` | Toggle Neovim workspace |
| `Super + Alt + G` | Toggle Gromit workspace (drawing) |

### Media & Function Keys

| Keybinding | Action |
|------------|--------|
| `XF86AudioLowerVolume` | Lower volume |
| `XF86AudioRaiseVolume` | Raise volume |
| `Super + F1` | Toggle microphone |
| `XF86AudioMute` | Toggle audio mute |
| `XF86MonBrightnessUp/Down` | Adjust brightness |
| `XF86AudioPlay/Next/Prev/Stop` | Media controls |
| `Super + F2` | Play/pause media |

### Miscellaneous

| Keybinding | Action |
|------------|--------|
| `Super + Y` | Open package manager (pamac) |
| `Super + F5` | Open input event viewer (wev) |
| `Super + Ctrl + D` | Open display settings (nwg-displays) |
| `Super + Alt + Space` | Open app drawer (nwg-drawer) |
| `Super + G` | Toggle game mode |
| `Super + F10` | Pass keys to OBS |
| `Ctrl + Alt + L` | Pass keys to QEMU |
| `Super + Shift + E` | Open terminal with editor |
| `Super + Shift + M` | Open emoji picker |
| `F8` | Gromit undo |
| `Shift + F8` | Gromit redo |

## Plugins

The configuration includes several plugins:
- hyprfocus: Window focus animations with shrink effect
- dynamic-cursors: Cursor behavior that changes based on movement (stretch mode)
- hypridle: Idle management

## Autostart Programs

Various programs are set to autostart, including:
- Network manager applet (nm-applet)
- Disk automounter (udiskie)
- Wallpaper daemon (swww-daemon)
- Notification daemon (swaync)
- Waybar
- Portal service (xdg-desktop-portal)
- Authentication agent (polkit-kde)
- Clipboard manager (cliphist + wl-paste)
- Terminal server mode (ghostty)
- Window switcher (hyprswitch)

## Window Rules

The configuration includes specific window rules:

- Picture-in-Picture windows: Automatically floated, resized, and positioned in the bottom-right corner
- Special tag "nopretty" for windows that shouldn't have blur or fancy effects
- Layer rules for proper handling of notification and menu components

## Power Management

The system is configured with progressive power management through hypridle:

| Timeout | Action |
|---------|--------|
| 2.5 minutes | Dim screen to 20% brightness and turn off keyboard backlight |
| 5 minutes | Lock screen |
| 5.5 minutes | Turn off displays |
| 30 minutes | Suspend system |

These actions are automatically canceled when activity is detected.

## Special Workspaces Configuration

The special workspaces are configured as follows:

```
workspace = special:gpt, gapsin:0, gapsout:0, on-created-empty: $browser --new-window https://www.chatgpt.com/
workspace = special:gemini, gapsin:0, gapsout:0, on-created-empty: $browser --new-window https://gemini.google.com/app
workspace = special:whatsapp, gapsin:0, gapsout:0, on-created-empty: $browser --new-window https://web.whatsapp.com/
workspace = special:nvim, gapsin:0, gapsout:0, on-created-empty: $terminal -e nvim '+set bt=nofile' FILE
workspace = special:gromit, gapsin:0, gapsout:0, on-created-empty: gromit-mpx -a
```