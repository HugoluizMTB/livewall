# livewall

Any HTML page as a live macOS wallpaper. One Swift file, no app to install, no dependencies beyond the Xcode command line tools.

Ships with an animated ASCII black hole (`examples/black-hole.html`).

## Install

```sh
git clone https://github.com/HugoluizMTB/livewall && cd livewall
./install.sh                 # the black hole
./install.sh my-page.html    # or any page of yours
```

It compiles `main.swift`, copies the page to `~/Library/Application Support/livewall/` and adds a LaunchAgent, so it starts at login.

## What it does

- One borderless window per display at desktop level, below the desktop icons, on every Space. Clicks pass through.
- Caps the page's `requestAnimationFrame` at 20 fps.
- Pauses the animation when a window covers 90% or more of a display, when the screen sleeps or locks, and when the Mac runs on battery.
- Rebuilds itself when displays are plugged in or out.

Uses about 0% CPU while paused. While animating it costs a few hundred MB of RAM (it is a WebKit view).

## Remove

```sh
./uninstall.sh
```

## Requirements

macOS 13 or later, `swiftc` (`xcode-select --install`).

## License

MIT
