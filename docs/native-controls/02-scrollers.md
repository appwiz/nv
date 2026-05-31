# Native Controls 02 — Custom scrollers → NSScroller

Companion to `docs/superpowers/specs/2026-05-30-native-controls-02-scrollers-spec.md`.

## What changed

The custom transparent-scroller stack and its opt-in preference are
gone. Every scroll view in the app now uses the system `NSScroller`
(overlay style by default, classic if the user sets that in System
Settings), which is appearance-aware out of the box.

## How

`ETScrollView` previously kept a `scrollerClass` ivar and a
`changeUseETScrollbarsOnLion` method that, on every preference
change, allocated either a custom `ETOverlayScroller` /
`ETTransparentScroller` or a plain `NSScroller` and reassigned the
vertical scroller. With the deployment target at 10.14 and the
preference defaulting to `NO`, every code path now ends at
"`NSScroller`," so the entire mechanism was removed.

The new `ETScrollView.m` is twenty lines: `awakeFromNib` sets
`autohidesScrollers:YES` when the document view is a table view, sets
the two scroll elasticities, and that's it.

`FocusRingScrollView.m` no longer substitutes `BodyScroller` for
`NSScroller` during NIB unarchive (the substitution was guarded by
`#if DELAYED_LAYOUT`, which wasn't defined anyway, but the import is
still gone).

`PreviewController.m` had a `!IsLionOrLater` branch that allocated a
`BTTransparentScroller` and assigned it to the source view's
enclosing scroll view. With the deployment target at 10.14 the branch
was dead code; it and the `BTTransparentScroller` import are gone.

## Removed pref / removed UI

`UseETScrollbarsOnLion` was the opt-in toggle. It is removed from:

- `GlobalPrefs.h` (declaration), `GlobalPrefs.m` (string key,
  registerDefaults seed, getter, setter).
- `PrefsWindowController.h` (`useETScrollbarsOnLionButton` outlet,
  `changedUseETScrollbarsOnLion:` action), `PrefsWindowController.m`
  (action body, `setState:` + `setHidden:!IsLionOrLater`
  initializers).
- The selector observer list in `AppController.m`'s
  `applicationDidFinishLaunching:` (the `registerWithTarget:` call).
- All six localized `Preferences.xib` files: the
  `useETScrollbarsOnLionButton` outlet line and the entire `<button>`
  block containing the action wiring were stripped via a small inline
  Python pass.

## Files

- **deleted (14 source files)**:
  - `BTransparentScroller.{h,m}`,
  - `BlueTransparentScroller.{h,m}`,
  - `WhiteTransparentScroller.{h,m}`,
  - `BTTransparentScroller.{h,m}`,
  - `ETOverlayScroller.{h,m}`,
  - `ETTransparentScroller.{h,m}`,
  - `BodyScroller.{h,m}`.

  Four of the seven classes (`BTransparentScroller`,
  `BlueTransparentScroller`, `WhiteTransparentScroller`,
  `BodyScroller`) were already not in the build (no PBXBuildFile
  entry); the remaining three (`BTTransparentScroller`,
  `ETOverlayScroller`, `ETTransparentScroller`) had their PBXBuildFile
  / PBXFileReference / group / Sources entries removed from
  `project.pbxproj`.

- **shrunk**:
  - `ETScrollView.h/.m` — now a 20-line `NSScrollView` subclass.

- **modified**:
  - `FocusRingScrollView.m` — dropped the `BodyScroller`
    substitution.
  - `PreviewController.m` — dropped the pre-Lion scroller branch and
    the `BTTransparentScroller` import.
  - `GlobalPrefs.h/.m` — removed `UseETScrollbarsOnLion` plumbing.
  - `PrefsWindowController.h/.m` — removed outlet, action,
    initializers.
  - `AppController.m` — removed the selector from the prefs callback
    list.
  - all six `*.lproj/Preferences.xib` — stripped the outlet line and
    the action button block.
  - `Notation.xcodeproj/project.pbxproj` — removed the build entries
    for the three previously-compiled scroller classes.

## Leftovers (deliberate, separate cleanup)

The 18 TIFF assets that the deleted scrollers used
(`BTransparentScrollerKnobBottom.tif` etc.,
`greyscrollervert*.tif*`, etc.) are still on disk and still appear in
the Resources build phase of the project. They're no longer
referenced from any code or NIB. They'll come out in a dedicated
asset-cleanup commit so this one stays focused on code.

## Verification

- `xcodebuild -arch arm64` succeeds. (Same deprecation warnings as
  before.)
- App launches; scroll views in the notes list and editor use the
  system scroller. *Preferences → Editing* no longer shows the
  "Use older-style scrollbars" checkbox.

## Reverting

```
git revert <this commit's hash>
```

restores all 14 deleted files, the original `ETScrollView`
implementation, the `UseETScrollbarsOnLion` preference plumbing, and
the XIB outlets/actions.
