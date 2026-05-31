# nvALT 2

A collaboration between Brett Terpstra (ttscoff) and David Halter (ElasticThreads) based on [DivineDominion's](github.com/divineDominion/nv) fork. nvALT adds a few features we'd been looking for (and let me get some coding practice).

![Screenshot](http://img.skitch.com/20110520-k5y4i6i3p8ciftq2dbs7rx64e7.jpg)

## Contents

- [About nvALT](#about-nvalt)
- [What it is](#what-it-is)
- [Additional Features](#additional-features)
- [iOS / iPadOS app (new)](#ios--ipados-app-new)
- [Build, run, test, develop](#build-run-test-develop)
- [Customization](#customization)
- [Download](#download)
- [Credits](#credits)

## About nvALT

nvALT is a fork of the original [Notational Velocity][notational] with some additional features and some interface modifications. It is a work in progress. I'm not listing it as a beta, as that would imply that it was on its way to being its own product. It's an experiment, and I hope you enjoy it!

## What it is

Notational Velocity is a way to take notes quickly and effortlessly using just your keyboard. You press a shortcut to bring up the window and just start typing. It will begin searching existing notes, filtering them as you type. You can use &#x2318;-J and &#x2318;-K to move through the list. Enter selects and begins editing. If you're creating a new note, you just type a unique title and press enter to move the cursor into a blank edit area. Check out the descriptions at [notational.net][notational] for a more eloquent synopsis.

## Additional Features

nvALT adds:

* Widescreen (horizontal) layout option
* Shortcut (&#x2318;-&#x2325;-N) to collapse the notes panel
* Markdown, Textile and MultiMarkdown support with Preview window
* HTML source code tab in the Preview window for fast copy/paste to blogs, etc.
* Unique interface design changes
* Fixes for a couple of bugs/annoyances
* Customizable HTML and CSS files for the Preview window
    * You can use Javascript in the templates to do a few neat tricks
* Native arm64 build on Apple Silicon (see [APPLE_SILICON_PORT.md](APPLE_SILICON_PORT.md))
* Modern dark-mode support (see [DARK_MODE.md](DARK_MODE.md))
* Refreshed native AppKit controls for the popover, scrollers, transparent buttons, table header, and corner view (see [docs/native-controls/](docs/native-controls/))

## iOS / iPadOS app (new)

The repository now ships a sibling **universal iOS app** alongside the
macOS app:

* Target name: **nvALT iOS**, product `nvALT iOS.app`, bundle ID `net.elasticthreads.nv.ios`
* Runs on iPhone and iPad from a single binary (`TARGETED_DEVICE_FAMILY = "1,2"`)
* Minimum deployment target: **iOS 16.0**
* iPad uses a two-column `UISplitViewController` layout; iPhone uses a navigation stack
* Notes persist as JSON to the app's sandboxed `~/Documents/nvalt_notes.json`
* Search-or-create-on-Return, swipe-to-delete, share sheet, automatic
  title-from-first-line, word/character count — the core nvALT note-taking
  loop, reproduced in UIKit

See [IOS_PORT.md](IOS_PORT.md) for a full design write-up explaining
the architecture, file layout, what is and isn't shared with the
macOS app, build settings, and suggested next steps.

## Build, run, test, develop

The repo uses a single Xcode project, **`Notation.xcodeproj`**, with
two native targets:

| Target | Platform | Schemes |
|---|---|---|
| `Notation` | macOS | `Notation Develop`, `Notation Release` |
| `nvALT iOS` | iOS / iPadOS | `nvALT iOS` |

### Requirements

* Xcode 14 or newer (developed against Xcode 26.5 with the macOS 26.5 SDK and iOS 26.5 simulator SDK)
* Apple Silicon Mac recommended; Intel works for source-level development but see *Known constraints* below
* No package manager dependencies — the macOS target links static
  OpenSSL libs already checked into the repo (`libssl.a`, `libcrypto.a`)

### Open it in Xcode

```sh
open Notation.xcodeproj
```

Pick a scheme from the toolbar and hit **Run** (⌘R).

### macOS — build and run from the command line

```sh
# Build (signed local dev build)
xcodebuild -project Notation.xcodeproj \
  -scheme "Notation Develop" -configuration Development build

# Build without a signing identity (e.g. CI, throwaway machines)
xcodebuild -project Notation.xcodeproj \
  -scheme "Notation Develop" -configuration Development \
  CODE_SIGNING_ALLOWED=NO build

# Launch the resulting app
open ~/Library/Developer/Xcode/DerivedData/Notation-*/Build/Products/Development/nvALT.app
```

For a stripped/optimised build, swap `Notation Develop` →
`Notation Release` and `Development` → `ForBuilding`. On Apple Silicon
add `-arch arm64 ONLY_ACTIVE_ARCH=YES` (see *Known constraints*).

### iOS / iPadOS — build and run on the Simulator

```sh
# Build for any iOS Simulator (covers iPhone + iPad)
xcodebuild -project Notation.xcodeproj \
  -scheme "nvALT iOS" -configuration Development \
  -destination "generic/platform=iOS Simulator" \
  CODE_SIGNING_ALLOWED=NO build

# Build & launch on a specific iPhone simulator
xcodebuild -project Notation.xcodeproj \
  -scheme "nvALT iOS" -configuration Development \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro" \
  CODE_SIGNING_ALLOWED=NO build
xcrun simctl boot "iPhone 17 Pro" 2>/dev/null || true
xcrun simctl install booted \
  ~/Library/Developer/Xcode/DerivedData/Notation-*/Build/Products/Development-iphonesimulator/nvALT\ iOS.app
xcrun simctl launch booted net.elasticthreads.nv.ios
open -a Simulator
```

Swap the simulator name for `iPad Pro 13-inch (M5)` (or any other
installed iPad simulator) to test the split-view layout.

### Running on a real device

You'll need an Apple Developer team:

1. Open the project in Xcode.
2. Select the `nvALT iOS` target → **Signing & Capabilities** → pick
   your team. (Xcode will offer to auto-generate a provisioning
   profile.)
3. Pick a connected iPhone or iPad from the run destinations and hit
   **Run**.

The macOS target is configured for team `47TRS7H4BH`; change it under
the `Notation` target's **Signing & Capabilities** tab to your own
team for local signed runs.

### Tests

This project has no automated test target. Verification is by
`xcodebuild` (compile + analyzer) plus manual smoke-testing in the
running app:

* macOS: typing notes, search, preview window, dark mode, syncing
  (if Simplenote configured).
* iOS: create-via-search-bar, edit, search/filter, swipe-delete,
  share, app backgrounding (notes should survive a force-quit).

### Where things live

* macOS sources — flat in the repo root (`AppController.{h,m}`,
  `NotationController.{h,m}`, `NotesTableView.{h,m}`, etc.)
* iOS sources — `iOS/` (see [IOS_PORT.md](IOS_PORT.md) for the
  per-file purpose)
* Shared resources — `*.lproj/`, `Images/`, `template.html`,
  `custom.css`, `Sparkle.framework`, `AutoHyperlinks.framework`
* Long-form design docs — `APPLE_SILICON_PORT.md`, `DARK_MODE.md`,
  `IOS_PORT.md`, `docs/native-controls/`

### Known constraints

* `Notation Release` defaults to a universal (arm64 + x86_64)
  binary, but the bundled `libssl.a` / `libcrypto.a` in the repo are
  arm64-only. A universal Release build fails to link the x86_64
  slice. Build arm64-only with
  `-arch arm64 ONLY_ACTIVE_ARCH=YES`, or replace the static libs with
  lipo'd fat archives if you need x86_64.
* The iOS app does **not** share its notes database with the macOS
  app — it has its own JSON store. Bridging the two is future work
  (see [IOS_PORT.md § Suggested next steps](IOS_PORT.md#suggested-next-steps)).

## Customization

Select "Open Custom CSS Folder" within the Preview menu, and the application's supprt folder will open. You will find two files:` template.html` and `custom.css`. If you're handy with HTML and CSS, feel free to customize these in whatever way you like. You can add Javascript as well, but you'll need to load external scripts from a url or using a full file:// path. If worst comes to worst, you can just delete or rename your customizations and the default files will be put back in place automatically when you select the menu item again.

## Download

More info and a download for the compiled binary can be found at [brettterpstra.com/projects/nvalt](http://brettterpstra.com/projects/nvalt/)

## Credits

* [Notational Velocity][notational]
* Code: The original Notational Velocity [source code][original source] by Zachary Schneirov
* Code: DivineDominion's [MultiMarkdown fork][DivineDominion]
* Inspiration: [Elastic Threads' version](http://elasticthreads.tumblr.com/nv) of Notational Velocity

[notational]: http://notational.net/
[original source]: https://github.com/scrod/nv
[DivineDominion]: https://github.com/DivineDominion/nv
