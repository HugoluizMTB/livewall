# livewall

Any HTML page as a live wallpaper, on macOS and on [Omarchy](https://omarchy.org) (Arch + Hyprland).

Ships with an animated ASCII black hole (`examples/black-hole.html`).

```
examples/   pages to use as wallpaper
mac/        macOS version: one Swift file
omarchy/    Omarchy / Hyprland version: C++, Qt WebEngine, layer-shell
```

## What it does

- Draws the page behind every window, on every display. Clicks pass through.
- Caps the page's `requestAnimationFrame` at 20 fps.
- Pauses the animation when a window covers 90% or more of a display (fullscreen games included), when the screen sleeps or locks, and when the machine runs on battery.
- Rebuilds itself when displays are plugged in or out.

Uses about 0% CPU while paused. While animating it costs a few hundred MB of RAM, because it is a web view.

## macOS

Requires macOS 13 or later and `swiftc` (`xcode-select --install`).

```sh
git clone https://github.com/HugoluizMTB/livewall && cd livewall
./mac/install.sh                 # the black hole
./mac/install.sh my-page.html    # or any page of yours
./mac/uninstall.sh               # remove
```

It compiles `mac/main.swift`, copies the page to `~/Library/Application Support/livewall/` and adds a LaunchAgent, so it starts at login.

## Omarchy (Hyprland)

Requires `qt6-webengine` and `layer-shell-qt` (`omarchy pkg add qt6-webengine layer-shell-qt`).

```sh
git clone https://github.com/HugoluizMTB/livewall && cd livewall
./omarchy/install.sh                 # the black hole
./omarchy/install.sh my-page.html    # or any page of yours
./omarchy/uninstall.sh               # remove
```

It builds with `qmake6`, installs `~/.local/bin/livewall`, copies the page to `~/.local/share/livewall/wallpaper.html` and adds `o.launch_on_start("livewall")` to `~/.config/hypr/autostart.lua`, so it starts with Hyprland.

The page sits on the layer-shell background layer, above Omarchy's own background, so theme changes keep working underneath. Coverage is read from `hyprctl` every 2 seconds.

## License

MIT
