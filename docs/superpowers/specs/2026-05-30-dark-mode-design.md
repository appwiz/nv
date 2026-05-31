# Dark Mode Support — Design

Date: 2026-05-30

## Goal

Make the app render correctly under both macOS Aqua and Dark Aqua,
following the system appearance automatically, including live switching
while the app is running. The Markdown Preview window follows the
system too.

## Decisions

| Question | Decision |
| --- | --- |
| How should the theme be picked? | Follow `[NSApp effectiveAppearance]` automatically. |
| Manual override? | None. The pre-existing `View → Color Schemes` submenu (B/W, LC, User) is removed in favour of one system-driven path. |
| User-customizable note background/foreground colors? | Removed. The two color wells in *Preferences → Editing* are gone, along with the `foregroundTextColor` / `backgroundTextColor` API on `GlobalPrefs` and the corresponding `UserDefaults` keys. |
| Markdown Preview theme? | Themed via a `prefers-color-scheme: dark` block in `custom.css` / `customclean.css`. The legacy `WebView` honours this on macOS 10.14+. |
| Deployment target? | Bumped to 10.14 (required for `NSAppearance` Dark Aqua support and `effectiveAppearance` KVO). |

## Architecture

A single static class, `NVAppearance`, is the source of truth for all
appearance-dependent colors used by custom-drawn views. Every accessor
resolves against `[NSApp effectiveAppearance]` at call time.

```
                +-----------------+
[NSApp]         |  NVAppearance   |
effective ----> |  +editorBg      | <---- custom-drawn views
appearance      |  +tableHeaderBg |       (per-draw or via the AppController
                |  +dividerFg     |        color pipe)
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

### Flow

1. `applicationDidFinishLaunching:` registers a KVO observer on
   `[NSApp] effectiveAppearance`. Window/app appearance are both left
   `nil` so they inherit from the system.
2. On launch and on every KVO callback, `applySystemAppearance` is
   invoked. It pulls a fresh foreground/background pair from
   `NVAppearance` and calls the existing `updateColorScheme` pipeline.
3. `updateColorScheme` propagates the new colors to the views that
   cache them (`mainView`, `textView`, `notesTableView`,
   `notationController`, `dividerShader`). It also marks the table
   header view and corner view for redraw; those views read from
   `NVAppearance` on each draw, so they re-theme without any cached
   state.

### Color reference points

`NVAppearance` doesn't return the system's dynamic `NSColor`s
(`+textColor`, `+textBackgroundColor`, …) because the editor wants a
slightly different surface than the system text background:

- **Light editor background**: `#FDFDFC` (warm paper).
- **Dark editor background**: `#1E1F22` (slightly elevated, not pure
  black, so the text doesn't look like raised type).

Other names follow the same pattern (the values are documented inline
in `NVAppearance.m`).

## Surface changes

### New files

- `NVAppearance.h` / `NVAppearance.m`

### Source edits

- `AppController.h/m`
  - removed: `userScheme` ivar, `setBWColorScheme:`,
    `setLCColorScheme:`, `setUserColorScheme:`, the two
    `setForegroundTextColor:` / `setBackgroundTextColor:` branches in
    the GlobalPrefs callback, and their selector observer
    registrations.
  - added: `applySystemAppearance`,
    `observeValueForKeyPath:ofObject:change:context:`, KVO
    registration in `applicationDidFinishLaunching:`, KVO
    deregistration in `applicationWillTerminate:`.
  - `backgrndColor` / `foregrndColor` lazy getters now return values
    from `NVAppearance` (no more `UserDefaults` reads).
  - `updateColorScheme` reads chrome colors from `NVAppearance` and
    invalidates the table header + corner view.
- `GlobalPrefs.h/m`
  - removed: `setForegroundTextColor:sender:`,
    `setBackgroundTextColor:sender:`, `foregroundTextColor`,
    `backgroundTextColor`, the `ForegroundTextColorKey` /
    `BackgroundTextColorKey` defaults seeds, and the
    `[NSColor blackColor]` / `[NSColor whiteColor]` seed values.
  - `searchTermHighlightColorRaw:` now blends against
    `[NVAppearance editorBackgroundColor]` instead of
    `[self backgroundTextColor]`.
- `PrefsWindowController.h/m`
  - removed: `foregroundColorWell` / `backgroundColorWell` outlets,
    `changedBackgroundTextColorWell:` / `changedForegroundTextColorWell:`
    actions, the well-initialization code in window setup.
- `NotesTableCornerView.m` — rewritten to draw straight from
  `NVAppearance`. Class-level `setBackColor:` / `setBordColor:` kept
  as no-op stubs for safety.
- `NotesTableHeaderCell.m` — rewritten. Reads `tableHeaderTextColor` /
  `tableHeaderBackgroundColor` / `tableGridColor` from `NVAppearance`.
  Class-level `setBColor:` / `setTxtColor:` kept as no-op stubs.
- `LinearDividerShader.m` — divider fallback colors now come from
  `NVAppearance.dividerForegroundColor` / `dividerBackgroundColor`.
- `UnifiedCell.m` — `dateColorForTint` returns
  `[NVAppearance tableDateTintColor]`. Highlighted text uses
  `alternateSelectedControlTextColor` instead of plain white so the
  source-list selection looks right under both appearances.
- `DualField.m` — search-bar fill uses
  `NVAppearance.fieldBackgroundColor`; the four edge strokes have an
  explicit dark-mode branch.
- `LinkingEditor.m` — removed the commented-out `prefsController`
  color path that referenced the deleted GlobalPrefs API.

### Nib edits

`MainMenu.xib` in all six locales (`en`, `de`, `fr`, `it`, `pt-PT`,
`zh`): the View → Color Schemes submenu and its status-bar twin were
stripped via `tools/strip_color_schemes.py`.

`Preferences.xib` in all six locales: the foreground/background color
well outlets, the `changed{Foreground,Background}TextColorWell:`
action wirings, and (in the English nib) the two `colorWell` objects
and their labels were removed. The non-English nibs keep the colorWell
shapes because their outlets are gone — the wells render but are
inert; subsequent localization passes can remove them.

### Resources

`custom.css` and `customclean.css` got a `:root { color-scheme: …; }`
declaration plus a `@media (prefers-color-scheme: dark)` block that
mirrors the existing light styles.

### Build settings

`MACOSX_DEPLOYMENT_TARGET` raised from 10.13 to 10.14 (in both
`Development` and `ForBuilding` configurations) because
`NSAppearanceNameDarkAqua` and KVO on `effectiveAppearance` are 10.14+.

## Known gaps (not in scope)

- The custom transparent scroller variants (`BTransparentScroller`,
  `WhiteTransparentScroller`, `BlueTransparentScroller`,
  `ETOverlayScroller`, `ETTransparentScroller`) hardcode light-palette
  TIFF assets. They are **off by default** (`UseETScrollbarsOnLion`
  defaults to `NO`), so the system overlay scroller — which is
  appearance-aware — is used. Users who enable the custom scrollers
  will see a light-palette scrollbar on a dark background.
- The `MAAttachedWindow` popups use a built-in translucent dark
  background; they look intentional in both appearances and aren't
  audited.
- The status-bar menu icon stays on the `nvMenuDark` template image.
  macOS handles template-image inversion automatically based on the
  menu bar color, so this works on both appearances.
- A handful of `NSUserDefaults` keys that the old User color scheme
  wrote (`ColorScheme`, `ForegroundTextColor`, `BackgroundTextColor`)
  are no longer read by the app. They remain in the user's defaults
  domain for old installs; we don't clean them up explicitly.

## Verification

- arm64 build of `Notation Develop` scheme with deployment target 10.14
  succeeds without errors. (Same deprecation warnings as before.)
- The app launches and runs natively (`lipo -archs` reports `arm64`).
- Manual smoke check: System Settings → Appearance toggle flips the
  app between light and dark while the app is running, no relaunch
  required, all view types refresh.
