# Native Controls Migration 02 — Custom scrollers → NSScroller

Date: 2026-05-30
Status: spec
Component: the custom `NSScroller` subclass stack
(`BTransparentScroller`, `BlueTransparentScroller`,
`WhiteTransparentScroller`, `BTTransparentScroller`,
`ETOverlayScroller`, `ETTransparentScroller`, `BodyScroller`) plus
the `UseETScrollbarsOnLion` preference that toggled some of them on.

## Problem

The project ships seven `NSScroller` subclasses that hand-paint a
transparent scroller with TIFF knob/slot images, plus an
`ETScrollView` subclass that swaps the system scroller for one of
them based on a user preference. The whole stack predates the system
overlay scrollers AppKit shipped in 10.7 and is opt-in:

- `UseETScrollbarsOnLion` defaults to `NO`. So in practice every
  user is already on the system overlay scroller.
- The TIFF assets are light-only (already documented as a known gap
  in `DARK_MODE.md`). Anyone who flipped the pref on would see a
  light-palette scroller on a dark surface.
- `PreviewController.m` installs `BTTransparentScroller` only on
  pre-Lion (`!IsLionOrLater`). Deployment target is 10.14 — the
  branch is dead code.
- `FocusRingScrollView.m` substitutes `BodyScroller` for `NSScroller`
  during NIB unarchive. That class adds nothing beyond a custom
  trough drawing that looks wrong in dark mode.

## Replacement

Use the system `NSScroller` everywhere. AppKit 10.14+ already
provides appearance-aware overlay scrollers; we don't need to draw
our own.

`ETScrollView` is reduced to a minimal `NSScrollView` subclass whose
`awakeFromNib` sets the two scroll-elasticity behaviours and
`autohidesScrollers` for table views. Everything else is dropped.

## Approach

1. Reduce `ETScrollView.m` to a minimal subclass: keep the
   `setHorizontalScrollElasticity:` / `setVerticalScrollElasticity:` /
   table-view `autohidesScrollers` logic. Drop the
   `useETScrollbarsOnLion` preference observation, the custom
   `scrollerClass` swap, and the manual tiling.
2. Delete the seven scroller classes:
   - `BTransparentScroller.{h,m}`
   - `BlueTransparentScroller.{h,m}`
   - `WhiteTransparentScroller.{h,m}`
   - `BTTransparentScroller.{h,m}`
   - `ETOverlayScroller.{h,m}`
   - `ETTransparentScroller.{h,m}`
   - `BodyScroller.{h,m}`
3. Strip `FocusRingScrollView.m`'s `BodyScroller`-substitution
   `awakeAfterUsingCoder:`.
4. Strip the `BTTransparentScroller` branch from
   `PreviewController.m`. Drop the import.
5. Remove the `UseETScrollbarsOnLion` preference:
   - `GlobalPrefs.h/.m`: remove the `useETScrollbarsOnLion` /
     `setUseETScrollbarsOnLion:sender:` API, the string constant, and
     the `registerDefaults:` seed.
   - `PrefsWindowController.h/.m`: remove the
     `useETScrollbarsOnLionButton` outlet, the
     `changedUseETScrollbarsOnLion:` action, and the
     `setState:` + `setHidden:!IsLionOrLater` initializers.
   - `AppController.m`: drop `@selector(setUseETScrollbarsOnLion:sender:)`
     from the prefs callback registration list.
6. Strip the now-orphan IBOutlet/IBAction wiring and the
   `useETScrollbarsOnLionButton` checkbox from every localized
   `Preferences.xib` (en, de, fr, it, pt-PT, zh) — same approach as
   we used for the color-well removal in the dark-mode change.
7. Remove all PBXBuildFile, PBXFileReference, group, and Sources
   entries for the deleted classes from `Notation.xcodeproj/project.pbxproj`.

## Files affected

- new: `docs/superpowers/specs/2026-05-30-native-controls-02-scrollers-spec.md`
- modified: `ETScrollView.m`, `FocusRingScrollView.m`,
  `PreviewController.m`, `GlobalPrefs.h`, `GlobalPrefs.m`,
  `PrefsWindowController.h`, `PrefsWindowController.m`,
  `AppController.m`, `Notation.xcodeproj/project.pbxproj`, all six
  `*.lproj/Preferences.xib` files.
- deleted: the 7 scroller-class header/implementation pairs (14
  files).

## Risks / open questions

- The custom TIFF assets (`BTTransparentScrollerKnobBottom.tif`,
  `greyscrollervertfill3.tif`, etc.) are still in the repo and Xcode
  project. They're no longer referenced from code. Leaving them in
  place is harmless; we can do a separate asset-cleanup pass.
- Anyone who had `UseETScrollbarsOnLion` set to `YES` in
  `NSUserDefaults` will silently get the system scroller now. No
  behaviour difference unless they were enjoying the custom look —
  matches "use native AppKit" goal.

## Verification

- arm64 build succeeds.
- App launches; scrolling in the notes list, the editor, and the
  preview source view uses the system scroller (overlay style by
  default, classic if the user picked that in System Settings).
- *Preferences → Editing* no longer shows the "Use older-style
  scrollbars" checkbox.
