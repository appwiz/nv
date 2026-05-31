# Dark Mode Implementation Notes

This document records how dark mode was added to the app and what
changed file-by-file. It is the companion to `APPLE_SILICON_PORT.md`.

The work landed in one commit:

- `c72e0be` — Add native dark mode support

A design-level write-up (decisions, alternatives considered) lives at
`docs/superpowers/specs/2026-05-30-dark-mode-design.md`. This file is
the *what was changed* counterpart.

## TL;DR

1. A new `NVAppearance` helper exposes named colors that resolve
   against `[NSApp effectiveAppearance]` at call time.
2. `AppController` KVO-observes `[NSApp] effectiveAppearance` and
   re-runs the existing `updateColorScheme` pipeline on every flip,
   so the app re-themes live with no relaunch.
3. The previous manual "Color Schemes" feature (View > B/W, Low
   Contrast, User Scheme) is removed in favour of a single
   appearance-driven path. The corresponding Preferences color wells
   and the `GlobalPrefs` API behind them are removed as well.
4. The Markdown Preview WebView follows the system appearance via a
   `prefers-color-scheme: dark` block added to `custom.css` and
   `customclean.css`.

## Architecture

```
                +-----------------+
[NSApp]         |  NVAppearance   |
effective ----> |  +editorBg      | <---- custom-drawn views
appearance      |  +tableHeaderBg |       (per-draw, or via the
                |  +dividerFg     |        AppController color pipe)
                |  ...            |
                +-----------------+
                        ^
                        |
            +-----------+------------+
            |  AppController         |
            |  - KVO observer on     |
            |    NSApp.effective-    |
            |    Appearance          |
            |  - applySystemAppear-  |
            |    ance: re-runs       |
            |    updateColorScheme   |
            +------------------------+
```

### Why a custom helper instead of `NSColor` semantic colors

`NSColor` provides system-resolved dynamic colors (`+textColor`,
`+textBackgroundColor`, `+labelColor`, …) that auto-adapt to system
appearance. We don't use them for the note surface because the editor
wants a slightly different background than the system text
background:

- **Light editor**: `#FDFDFC` — a warm "paper" white, not pure white.
- **Dark editor**: `#1E1F22` — slightly elevated above pure black so
  the text doesn't read as raised type.

The system semantic colors *are* still used in a few specific places
where they look correct out of the box — e.g. `+alternateSelected-
ControlTextColor` for the highlighted row text in `UnifiedCell`.

### How the live flip works

1. `applicationDidFinishLaunching:` adds a KVO observer on
   `[NSApp] effectiveAppearance`. The window and app appearances are
   left `nil` so they inherit from the system.
2. When the system flips, the KVO callback bounces the work onto the
   main queue if needed, then calls `applySystemAppearance`.
3. `applySystemAppearance` re-asks `NVAppearance` for the current
   editor foreground/background and re-runs the existing
   `updateColorScheme` pipeline.
4. `updateColorScheme` (a) writes the new colors into the views that
   cache them (`mainView`, `textView`, `notesTableView`,
   `notationController`, `dividerShader`) and (b) marks the table
   header view and corner view for redraw. Those two read colors
   from `NVAppearance` on each `drawRect:`, so they never need
   external cache invalidation.

## File-by-file changes

### New files

- **`NVAppearance.h` / `NVAppearance.m`** — the appearance helper. All
  named colors used by custom drawing live here. Each accessor calls
  `+isDark` (which resolves `[NSApp effectiveAppearance]` via
  `bestMatchFromAppearancesWithNames:` against Aqua / Dark Aqua and
  their high-contrast variants) and returns the appropriate value.

- **`docs/superpowers/specs/2026-05-30-dark-mode-design.md`** —
  the design spec produced by the brainstorming pass.

- **`tools/strip_color_schemes.py`** — small helper used to remove
  the `Color Schemes` submenu from each localized `MainMenu.xib`.
  Walks back two levels of `<menuItem>` nesting from each
  `setBWColorScheme:` action to find the wrapping submenu and
  deletes it whole.

### `AppController.h` / `AppController.m`

- Removed the `userScheme` ivar and its IBAction trio
  `setBWColorScheme:`, `setLCColorScheme:`, `setUserColorScheme:`.
- Removed the two pref-callback branches that reacted to
  `setForegroundTextColor:sender:` / `setBackgroundTextColor:sender:`
  and the corresponding entries in the
  `[prefsController registerWithTarget:forChangesInSettings:]` list.
- Replaced the launch-time scheme-restore block in `awakeFromNib`
  with a single `[self applySystemAppearance]` call.
- Added the new methods:
  - `-applySystemAppearance` — pulls colors from `NVAppearance`,
    calls `updateColorScheme`.
  - `-observeValueForKeyPath:ofObject:change:context:` — bounces to
    main queue if needed and invokes `applySystemAppearance`.
- Rewrote `-updateColorScheme` to feed chrome colors from
  `NVAppearance` (table grid, header text colors, divider) and to
  invalidate the table header view and corner view so they redraw
  through the new color path.
- Rewrote the lazy `-backgrndColor` / `-foregrndColor` getters to
  return `NVAppearance` values instead of unarchiving from
  `UserDefaults` and switching on `userScheme`.
- `applicationDidFinishLaunching:` now sets `NSApp.appearance` /
  `window.appearance` to `nil` (follow system) and registers the KVO
  observer on `[NSApp] effectiveAppearance`.
- `applicationWillTerminate:` removes the KVO observer.
- Removed the now-dead `IsLionOrLater` window-background branch.

### `GlobalPrefs.h` / `GlobalPrefs.m`

- Removed the public API:
  - `-setForegroundTextColor:sender:`
  - `-foregroundTextColor`
  - `-setBackgroundTextColor:sender:`
  - `-backgroundTextColor`
- Removed the `ForegroundTextColorKey` and `BackgroundTextColorKey`
  static `NSString` constants and the two corresponding entries in
  the `registerDefaults:` dictionary
  (`[NSColor blackColor]` / `[NSColor whiteColor]`).
- `-searchTermHighlightColorRaw:` now blends against
  `[NVAppearance editorBackgroundColor]` instead of
  `[self backgroundTextColor]`. (`#import "NVAppearance.h"` added.)

### `PrefsWindowController.h` / `PrefsWindowController.m`

- Removed the IBOutlets `foregroundColorWell` and
  `backgroundColorWell` (only `searchHighlightColorWell` remains in
  that line).
- Removed the IBActions
  `changedForegroundTextColorWell:` and
  `changedBackgroundTextColorWell:`.
- Removed the two `setColor:` initializers that pulled the well
  values out of `GlobalPrefs` on window load.

### `NotesTableCornerView.m`

Rewritten. Drops the static `bColor` / `fColor` / `cGradient` cache
and the cell-gradient pass. `drawRect:` now pulls
`tableCornerFillColor` and `tableCornerBorderColor` from
`NVAppearance` on every draw. The class-level `+setBackColor:` /
`+setBordColor:` entry points are kept as no-op stubs in case any
external caller still pokes at them.

### `NotesTableHeaderCell.m`

Rewritten. The previous version cached two static `NSColor`s,
applied a gradient fill, and drew a complex border. The replacement:

- Pulls `tableHeaderTextColor`, `tableHeaderBackgroundColor`, and
  `tableGridColor` from `NVAppearance` on every draw.
- Draws a flat fill instead of a gradient — looks correct under both
  appearances without per-appearance gradient stops.
- Keeps the column-separator stroke logic but uses the appearance
  grid color.
- `+setBColor:` / `+setTxtColor:` kept as no-op stubs.

### `LinearDividerShader.m`

The divider's fallback colors (used before
`updateColorsWithBackgroundColor:andForegroundColor:` is called and
when called with nil) now come from
`[NVAppearance dividerForegroundColor]` /
`[NVAppearance dividerBackgroundColor]` instead of
`[NSColor grayColor]` / `[NSColor lightGrayColor]`. The blend logic
inside the shader was already adaptive to background whiteness, so it
needed no change — feeding it dark colors produces a correctly dark
divider gradient.

### `UnifiedCell.m`

- `+dateColorForTint` now returns `[NVAppearance tableDateTintColor]`
  unconditionally. The old per-`NSControlTint` branches read
  `[NSColor currentControlTint]` and produced one of three light-mode
  RGB values; under dark mode those values were nearly invisible.
- The "highlighted row" text color path uses
  `+alternateSelectedControlTextColor` instead of `+whiteColor`, so
  inactive source-list selections look right.

### `DualField.m`

- The search-bar fill rect is now drawn with
  `[NVAppearance fieldBackgroundColor]` instead of
  `[NSColor whiteColor]`.
- The four horizontal edge strokes (`topEdge`, `topInner`,
  `bottomEdge`, `bottomHighlight`) have a dark-mode branch with
  darker values that produces a similar relief effect on dark
  surfaces.
- The text-color path uses `[NVAppearance fieldTextColor]` instead of
  the unconditional `[NSColor blackColor]` previously gated on
  `IsYosemiteOrLater`.

### `LinkingEditor.m`

- Removed a stale commented block that referenced
  `[prefsController foregroundTextColor]` /
  `[prefsController backgroundTextColor]`. The live path was already
  reading the AppController's `foregrndColor` / `backgrndColor`, which
  are now `NVAppearance`-driven.

### `custom.css` / `customclean.css`

Appended:

```css
:root { color-scheme: light dark; }

@media (prefers-color-scheme: dark) {
  body, p, td, div { color: #d8dadf }
  a            { color: #77bdfb }
  a:hover      { color: #a8d4fc }
  h1.doctitle  { background: #1f2125; color: #ebecef;
                 border-bottom-color: #2c2f35 }
  h1, h2, h3, h4 { color: #ebecef }
  h2 em        { color: #a8acb5; text-shadow: 0 1px 0 #000 }
  .footnote    { color: #77bdfb }
  @media screen {
    #wrapper      { background: #1e1f22;
                    -webkit-box-shadow: inset 0px 0px 4px #000 }
    #contentdiv   { color: #d8dadf }
    #contentdiv::-webkit-scrollbar-thumb { background: #555 }
  }
  @media print {
    #wrapper      { background: #fff }
    #contentdiv   { color: #303030 }
  }
}
```

The legacy `WebView` honours `prefers-color-scheme` on macOS 10.14+
as long as the WebView's effective appearance follows the system, so
no Obj-C-side change to `PreviewController` is needed.

### XIBs

`MainMenu.xib` — all six locales (`en`, `de`, `fr`, `it`, `pt-PT`,
`zh`). The `View > Color Schemes` submenu and its status-bar twin
(B/W, Low Contrast, User Scheme items + their actions) were removed.
For the English nib this was a hand edit; for the other five the
`tools/strip_color_schemes.py` script walked back two `<menuItem>`
nesting levels from each `setBWColorScheme:` action to find the
wrapping submenu and delete it whole.

`Preferences.xib` — all six locales. Removed:

- The `foregroundColorWell` outlet wire.
- The `backgroundColorWell` outlet wire.
- The `changedForegroundTextColorWell:` action wire.
- The `changedBackgroundTextColorWell:` action wire.
- In the English nib only, the two `<colorWell>` objects (ids 396 /
  400) and the two `<textField>` labels ("Foreground Text:" /
  "Background:") were also deleted. The five non-English nibs still
  contain the colorWell shapes, but with their outlets and actions
  removed they're inert; cleaning those up is left for a later
  localisation pass.

### `Notation.xcodeproj/project.pbxproj`

- Added three entries (PBXBuildFile, two PBXFileReference, group
  membership, Sources build phase) for `NVAppearance.h` /
  `NVAppearance.m`. The IDs use a unique sentinel prefix
  (`DA17DA17DA17DA17DA170001…`) to avoid colliding with any of the
  hex-style IDs already in the project.
- Raised `MACOSX_DEPLOYMENT_TARGET` from 10.13 → 10.14 in both
  `Development` and `ForBuilding` configurations (Dark Aqua and KVO
  on `effectiveAppearance` are 10.14+).

## Known gaps

| Item | Status | What to do |
| --- | --- | --- |
| Custom transparent scrollers | Off by default | `UseETScrollbarsOnLion` defaults to `NO`, so the system overlay scroller is used and it's appearance-aware. Users who opt in to `BTransparentScroller`/`ETOverlayScroller`/etc. will see light-palette TIFF knobs on a dark background. Each scroller has hardcoded TIFFs in the asset list. Replacement requires either appearance-aware drawing or a second set of TIFFs. |
| `MAAttachedWindow` popups | Already dark | Uses a translucent dark background by design. Looks intentional in both appearances. |
| Status-bar menu icon | Already adapts | `nvMenuDark` is shipped as a template image; AppKit handles inversion based on the menu bar colour. |
| Orphan `UserDefaults` keys | Left in place | The old User color scheme wrote `ColorScheme`, `ForegroundTextColor`, and `BackgroundTextColor` to `NSUserDefaults`. The app no longer reads them. They stay in upgraded users' defaults domain; we don't proactively delete them. |

## Build and verify

```
xcodebuild -scheme "Notation Develop" -configuration Development \
  -arch arm64 ONLY_ACTIVE_ARCH=YES \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO build
```

To confirm live switching: flip System Settings → Appearance between
Light and Dark while the app is running. The window chrome, notes
list, editor surface, search bar, divider, and an open Markdown
Preview should all re-theme without a relaunch.
