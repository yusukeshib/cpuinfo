# cpuinfo

A tiny macOS menu bar app that shows live CPU usage as a compact meter.

![idle](res/menubar-idle.png?raw=true) &nbsp; ![load](res/menubar-load.png?raw=true)

The bar is green when the machine is mostly idle and turns orange / red as load
rises. Click it for options.

## Features

- **Overall meter** — a slim pill that fills left → right with total CPU usage.
- **Per-core mode** — a compact vertical-bar equalizer, one bar per logical core.
- **Optional percentage text** next to the bar.
- **Light / dark adaptive** — follows the system appearance.
- **Themes** — `Default` (color) and `B/W` (monochrome).
- **Adjustable update interval** — 0.1s up to 30s.
- **Start at login** (via a bundled login-item helper).
- **Open Activity Monitor** shortcut.

## Requirements

- macOS 10.13 or later.

## Build & run

The app is written in Swift. You need Xcode or the Command Line Tools, but you
never have to open the Xcode IDE — a `Makefile` wraps `xcodebuild`:

```sh
make build     # build (Debug, unsigned)
make test      # run the unit tests
make run       # build and launch
make zip       # package the Release app into dist/cpuinfo.zip
make release   # build in Release configuration
make clean     # remove build artifacts
```

Override defaults as needed, e.g. `make build CONFIGURATION=Release` or
`make build CODE_SIGNING_ALLOWED=YES`.

CI (GitHub Actions) builds and tests on every push/PR, and a tagged `v*` push
produces a release artifact (optionally code-signed + notarized when signing
secrets are configured).

## Install

Download the latest zip from the [Releases](../../releases) page, unzip, and
move `cpuinfo.app` to `/Applications`.

> The released build is **not notarized**, so on first launch Gatekeeper will
> block it. Right‑click the app → **Open**, or clear the quarantine flag:
> ```sh
> xattr -dr com.apple.quarantine /Applications/cpuinfo.app
> ```

## Project layout

| Path | What |
| --- | --- |
| `src/Cpuinfo.swift` | CPU sampler (Mach `host_statistics` / `host_processor_info`) |
| `src/CpuinfoImage.swift` | `NSImage` subclass that renders the meter |
| `src/CpuinfoDelegate.swift` | App delegate: status item, menu, sampling loop |
| `src/StartAtLoginController.swift` | Login-item management (`SMAppService` / legacy) |
| `helper/` | Login-item helper app that relaunches the main app |
| `tests/` | Unit tests for the usage math |
| `cpuinfo.plist` | App Info.plist + theme definitions |

## License

```
The MIT License (MIT)

Copyright (c) 2016 Yusuke Shibata

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
```
