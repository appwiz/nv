# iOS / iPadOS Port — Design Notes

This document explains how the legacy macOS-only **nvALT** Cocoa
codebase was extended into a universal app that also runs on iPhone
and iPad as **nvALT iOS**.

It is paired with [APPLE_SILICON_PORT.md](APPLE_SILICON_PORT.md), which
covered the preceding work of getting the macOS app building natively
on Apple Silicon under modern Xcode.

The iOS work landed in one commit:

- `4d03129` — Add universal iOS/iPadOS target (nvALT iOS)

## Scope and non-goals

nvALT on macOS is a 15+ year old AppKit application built around
`NotationController` — a heavyweight directory-watching notes database
with sync (Simplenote), encryption, WAL journaling, Markdown/MultiMarkdown
preview, ODB editor integration, etc. It was authored long before
ARC, iOS multi-window, scenes, or UIKit, and many of its classes
either inherit from `NS…` types that have no UIKit equivalent
(`NSWindow`, `NSTableView`, `NSTextView`) or call AppKit-only APIs
deep in their guts.

**The goal of this port is not to lift the macOS engine onto iOS.**
Doing so cleanly would require either a full Mac-Catalyst conversion
or extensive `#if TARGET_OS_OSX` shimming of `NotationController`,
`LinkingEditor`, `NotesTableView`, `AppController` and dozens of
sibling classes. Both paths were rejected in favour of a far smaller,
shippable footprint:

1. Keep the macOS app **byte-identical** to its pre-port state.
2. Add a **new, separate UIKit application target** living in `iOS/`
   with its own thin notes model, persistence, and view controllers.
3. Share at the source level only when the upstream class is already
   Foundation-only or trivially portable.

This trades some long-term code reuse for a clean separation that
keeps the macOS build out of `#ifdef` hell and lets the iOS app be
iterated on independently.

## Target structure

The Xcode project (`Notation.xcodeproj`) now contains **two native
targets** sharing one workspace:

| Target | Platform | Product | Bundle ID | Min OS |
|---|---|---|---|---|
| `Notation` | macOS | `nvALT.app` | `net.elasticthreads.nv` | 10.14 |
| `nvALT iOS` | iOS, iPadOS | `nvALT iOS.app` | `net.elasticthreads.nv.ios` | 16.0 |

Schemes:

- **Notation Develop** — macOS, signed for local dev, fast iteration.
- **Notation Release** — macOS, `ForBuilding` configuration, intended
  for shipping. (Currently arm64-only on this machine; see
  *Known constraints* below.)
- **nvALT iOS** — universal iOS app (`TARGETED_DEVICE_FAMILY = "1,2"`)
  using `iphoneos` SDK, `IPHONEOS_DEPLOYMENT_TARGET = 16.0`.

The iOS target's build phases are kept **completely independent** of
the macOS target's source list: no files in the project root are
compiled into `nvALT iOS`, and none of the iOS-only files are compiled
into `Notation`. This is enforced by listing only the iOS sources in
the `Sources (iOS)` build phase. As a result, opening the project on a
machine without the macOS SDK does not break the iOS build, and vice
versa.

## File layout

All iOS-only code lives in a sibling `iOS/` directory at the project
root:

```
iOS/
├── AppDelegate_iOS.{h,m}         UIApplicationDelegate stub
├── SceneDelegate_iOS.{h,m}       Scene lifecycle, picks root VC
├── main_iOS.m                    UIApplicationMain entry point
├── Info-iOS.plist                Scene manifest, URL types, orientations
│
├── NVNote.{h,m}                  Plain-object note model
├── NVNotesManager.{h,m}          Singleton store + JSON persistence
│
├── NoteListViewController.{h,m}  Primary column: search + list
├── NoteEditorViewController.{h,m} Detail column: title + body + share
└── NVSplitViewController.{h,m}   iPad two-column container
```

There is intentionally **no XIB or storyboard**. Everything is built
programmatically in `-viewDidLoad`. This avoids touching the macOS
project's existing XIBs and removes any temptation for Xcode to
auto-edit shared resources when the iOS target is selected.

## Application lifecycle

The iOS target uses the modern **scene-based** lifecycle (iOS 13+),
configured via `UIApplicationSceneManifest` in `Info-iOS.plist`:

- `main_iOS.m` calls `UIApplicationMain` with `AppDelegate_iOS`.
- `AppDelegate_iOS` is intentionally minimal — it owns no UI; scenes do.
- `SceneDelegate_iOS` builds the root view controller in
  `scene:willConnectToSession:options:`, picking between iPhone and
  iPad layouts via `UIDevice.currentDevice.userInterfaceIdiom`:
  - **iPad** → `NVSplitViewController` (UISplitViewController subclass)
    with the note list as primary column and the editor as detail.
  - **iPhone** → a single `UINavigationController` rooted at the list.
- `sceneDidEnterBackground:` calls `[NVNotesManager saveNotes]` so
  edits survive a process kill.

This mirrors the universal-app convention from Apple's own
`UISplitViewController` templates; the same binary handles both idioms
without separate executables.

## Data model and persistence

Rather than try to port `NotationController` — which mmaps a
catalog file, runs a WAL, hashes per-note data with broken-MD5 for
backwards-compat, etc. — the iOS target introduces a deliberately
small replacement.

### `NVNote`

A plain `NSObject` with six properties: `title`, `content`, `tags`,
`createdDate`, `modifiedDate`, `uniqueID`. Round-trips through
`NSDictionary` (`-initWithDictionary:` / `-toDictionary`) so the whole
notes array serializes to JSON in one line.

### `NVNotesManager`

A `sharedManager` singleton over a `NSMutableArray<NVNote *>`. It:

- Persists to `~/Documents/nvalt_notes.json` (sandboxed per-app
  Documents directory).
- Loads at scene-connect time, saves on every CRUD operation **and**
  on backgrounding.
- Holds a `searchString`, exposes a derived `filteredNotes` array
  (`title|content|tags CONTAINS[cd] %@`, sorted by `modifiedDate
  DESC`).
- Posts `NVNotesManagerDidChangeNotification` after every mutation;
  view controllers subscribe and reload.

This is **not** designed to interop with the macOS notes database. A
future sync layer would need to either teach the iOS app the on-disk
nvALT catalog format, or run both clients against an external service
like Simplenote, iCloud, or a file-watching shim over the macOS notes
directory. None of that is in scope here.

## UI layer

### List (`NoteListViewController`)

The classic nvALT "type to search or create" interaction is preserved
on iOS by using a `UISearchController` whose text doubles as the
new-note title. Specifically:

- The search field's `placeholder` is `"Search or create note…"`.
- `updateSearchResultsForSearchController:` pipes the live query into
  `NVNotesManager.searchString` → the filtered table reloads.
- Pressing Return (`searchBarSearchButtonClicked:`):
  - If the query exactly matches a note title (case-insensitive), open
    it.
  - Else if exactly one note matches the filter, open that one.
  - Else create a new note with the query as its title and open it.
- The `+` toolbar button creates a new note using whatever is in the
  search field as a title seed.

Rows show title + a content preview (first two lines) via
`UITableViewCellStyleSubtitle`. Swipe-to-delete is wired through
`commitEditingStyle:`.

`openNote:` chooses where the editor goes:

- If `self.splitViewController` is non-nil (iPad), the editor is
  installed as the detail column's root and `showDetailViewController:`
  reveals it.
- Otherwise (iPhone) it's pushed onto the navigation stack.

### Editor (`NoteEditorViewController`)

A plain UIKit layout (no Markdown rendering yet):

- `UITextField` for title (bold, 18pt).
- A 1pt separator view.
- `UITextView` for content (16pt system).
- A small `UILabel` status bar showing word + character counts,
  updated on each `textViewDidChange:`.
- Right bar button is `UIBarButtonSystemItemAction` →
  `UIActivityViewController` with the note's title + body.

Keyboard avoidance is handled manually via
`UIKeyboardWillShow/HideNotification`: the content view's
`contentInset` and `scrollIndicatorInsets` animate in step with the
keyboard frame.

Auto-titling: if the user leaves the title field blank, on save the
first line of the body (capped at 60 chars) becomes the title. Empty
title **and** empty body deletes the note — same as desktop nvALT.

### Split (`NVSplitViewController`)

A small `UISplitViewController` subclass used on iPad. It:

- Sets `preferredDisplayMode = .oneBesideSecondary` (visible sidebar).
- Wraps the list in a `UINavigationController` (primary) and a
  placeholder editor in another (secondary).
- Implements `collapseSecondaryViewController:onto:` so that when the
  iPad rotates into a compact width, only the list is shown if no
  note is selected.

## Build configuration

iOS-target build settings (Development and ForBuilding configs share
these):

```
SDKROOT                      = iphoneos
IPHONEOS_DEPLOYMENT_TARGET   = 16.0
TARGETED_DEVICE_FAMILY       = "1,2"          # iPhone + iPad
PRODUCT_BUNDLE_IDENTIFIER    = net.elasticthreads.nv.ios
INFOPLIST_FILE               = iOS/Info-iOS.plist
HEADER_SEARCH_PATHS          = $(PROJECT_DIR)/iOS
CLANG_ENABLE_OBJC_ARC        = YES
CLANG_ENABLE_MODULES         = YES
SWIFT_VERSION                = 5.0            # for forward-compat
```

ARC is on for the iOS target (the macOS target remains non-ARC, as
the existing code was written pre-ARC and relies on manual memory
management in several places).

The iOS target links no third-party frameworks — Sparkle, OpenSSL,
AutoHyperlinks etc. are macOS-only and intentionally excluded from
the iOS link line.

## Known constraints

1. **No shared notes database.** As discussed above, the iOS app has
   its own JSON store at `~/Documents/nvalt_notes.json`. Bridging this
   to the macOS app's notes catalog is future work.
2. **No Markdown preview, no encryption, no Simplenote sync** in the
   iOS build yet. The classes that implement these on macOS
   (`PreviewController`, `NotationPrefs`, `SimplenoteSession`) all
   depend on AppKit and/or `NotationController` and would each require
   a port.
3. **`Notation Release` x86_64 link fails on this machine.** The
   bundled `libssl.a`/`libcrypto.a` in the repo are arm64-only, so a
   universal Release build cannot satisfy the x86_64 link. Building
   Release with `-arch arm64 ONLY_ACTIVE_ARCH=YES` succeeds. To
   produce a true universal Release binary, swap the static OpenSSL
   libs for lipo'd fat archives (or drop x86_64 from
   `VALID_ARCHS`/`ARCHS`). This is a pre-existing constraint inherited
   from the Apple Silicon port; it is **not** introduced by the iOS
   work.
4. **No automated test target.** The macOS app never had a test
   target; the iOS app continues that legacy. Smoke-testing is by
   `xcodebuild` and Simulator runs.

## How to verify the port

```sh
# macOS — Develop (arm64, code-signing disabled for headless build)
xcodebuild -project Notation.xcodeproj \
  -scheme "Notation Develop" -configuration Development \
  CODE_SIGNING_ALLOWED=NO build

# iOS — generic simulator destination (covers both iPhone and iPad SDK)
xcodebuild -project Notation.xcodeproj \
  -scheme "nvALT iOS" -configuration Development \
  -destination "generic/platform=iOS Simulator" \
  CODE_SIGNING_ALLOWED=NO build

# iPhone-specific simulator
xcodebuild -project Notation.xcodeproj \
  -scheme "nvALT iOS" -configuration Development \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro" \
  CODE_SIGNING_ALLOWED=NO build

# iPad-specific simulator
xcodebuild -project Notation.xcodeproj \
  -scheme "nvALT iOS" -configuration Development \
  -destination "platform=iOS Simulator,name=iPad Pro 13-inch (M5)" \
  CODE_SIGNING_ALLOWED=NO build
```

All four invocations should print `** BUILD SUCCEEDED **`. Analyzer
warnings on `NoteListViewController.m` and `NoteEditorViewController.m`
are non-fatal and unrelated to functionality.

## Suggested next steps

In rough order of effort and value:

1. **Markdown rendering in the editor** — drop in a `WKWebView` or a
   Down/cmark-based attributed-string renderer; reuse the macOS
   `custom.css` from `Resources`.
2. **iCloud document store** for `nvalt_notes.json`, so the iOS app
   syncs across devices via Apple infrastructure.
3. **Simplenote bridge** — port `SimplenoteSession.m` (mostly NSURL
   + JSON, already Foundation-only) and have both targets share it.
4. **Shared model layer** — extract a portable `NVNoteCore` static
   library/framework that both targets link against, replacing the
   current source-level fork between `NoteObject` (macOS) and `NVNote`
   (iOS).
5. **Mac Catalyst evaluation** — once enough functionality is on the
   iOS side, revisit whether Catalyst could let us retire the AppKit
   target without losing features. (Probably not soon: the macOS UI
   has too many AppKit-specific controls — custom split-view dimples,
   the tags column cell, the unified status bar — that have no clean
   Catalyst path.)
