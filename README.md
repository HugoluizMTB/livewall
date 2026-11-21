# livewall

Any HTML page as a live wallpaper, on macOS and on [Omarchy](https://omarchy.org) (Arch + Hyprland).

Ships with two pages:

- `examples/black-hole.html`: an animated ASCII black hole.
- `examples/ascii-weather.html`: the live sky from [webgl-weather](https://github.com/HugoluizMTB/webgl-weather), redrawn in ASCII. Sky color by the hour, sun, moon in today's real phase, stars, clouds, rain, drops on the glass, lightning, and the temperature drawn in big characters. Data from [Open-Meteo](https://open-meteo.com), place from your IP via [BigDataCloud](https://www.bigdatacloud.com). Open it in a browser to get a control panel (conditions, hour, time-lapse, cloud, rain, storm, wind); the panel stays hidden on the desktop. Preview a condition with `?condition=storm&hour=15`.

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
- On Omarchy, reloads the page if its renderer crashes, and logs the page's console to the journal.

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
