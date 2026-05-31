# Native Controls 19 — Settings (Preferences) layout redesign

End-to-end redesign of the Settings window driven by interactive
screenshots (s1–s4.png from the previous iteration) and the mocks the
user iterated on in
`docs/superpowers/specs/2026-05-31-native-controls-19-prefs-layout-mocks.md`.

Supersedes commit-18's targeted polish — this is the broader rework.

## Toolbar & window chrome

- Window title is now fixed at `Settings`; the active pane name moves
  into `window.subtitle` (macOS 11+).
- `window.toolbarStyle = NSWindowToolbarStyleExpanded` (macOS 11+) so
  the four toolbar items render on their own row beneath the title
  bar, instead of competing with the title for horizontal space in a
  single row.
- `switchViews:` rewritten around
  `[window frameRectForContentRect:]` so the chrome math is correct on
  modern macOS — fixes the bottom-of-pane clipping (e.g. "Hide Dock
  Icon" half-cut). `prefsView` is sized to fill the new content rect
  before installation, so wider window + narrower pane no longer
  leaves stale subview frames.
- `contentMinSize` lowered to 500×200 (was 580×200 when the toolbar
  shared a row with the title).
- Toolbar small-size mode removed — regular size mode looks correct in
  the dedicated row.

## All four panes widened to a unified 500pt

`generalView`, `databaseView` + inner `notationPrefsView`,
`editingView`, `fontsColorsView` are all resized to width 500 so the
window stays the same width as you tab through panes. Children stay
left-anchored via existing autoresizing masks.

## General pane

Spec mock:

```
[ ] Use large font for List Text

[ ] Auto-select notes by title when searching
    Automatically selecting very long notes may affect responsiveness.

[ ] Confirm note deletion
[ ] Quit when closing window
[ ] Show menu bar icon
------------------------------------------------------------------
{ Hide Dock Icon }
```

- Removed: `List Text Size:` popup + label; `Bring-to-Front Hotkey:`
  label/field/Set… button; the always-hidden "This will immediately
  restart nvALT" label.
- Added: `Use large font for List Text` checkbox at top, bound to a
  new `changedListFontSize:` action that flips `tableFontSize` between
  `[NSFont smallSystemFontSize]` (off) and 12pt (on).
- View height tightened 286 → 248.

## Notes pane

- Programmatically removes the `Synchronization` sub-tab from the
  inner `NSTabView` at `NotationPrefsViewController -awakeFromNib`,
  via a new `nv_findTabViewInView:` recursive walker. Storage and
  Security sub-tabs remain.
- `NotationPrefsView.nib` (compiled binary in `en.lproj/`) is
  regenerated from a decompiled XIB so the new layout is reproducible.
  Sources committed at `NotationPrefsView.xib` at the repo root for
  future maintenance. The build still consumes the compiled `.nib`
  bundle from `en.lproj/`.
- Storage sub-tab reflowed: `Store and read notes on disk as:` label
  and popup now share the top row (label right-aligned at x=10 ending
  at x=210, popup at x=215 w=148); `Confirm note files removed in the
  Finder` checkbox moved up under the popup (y=270); the
  `* Using separate files…` helper moved to the bottom of the tab
  (y=8); `Recognize individual files with attributes:` label moved
  closer to the tables (y=240). Tables and `+/-/★` button strip
  unchanged in this pass.
- Security sub-tab untouched in this pass — its current layout matches
  the spec mock well enough.

## Editing pane

- Removed: `Direction:` label + RTL checkbox; `Process with
  Readability` checkbox; `Hold down Option while dragging…` helper.
- All remaining top-of-pane elements shifted down 80pt to close the
  gap left by the removed rows.
- `URL Import:` label height shrunk 34 → 17 (single line now that
  Process Readability is gone).
- `External Editor:` row label shortened to `Editor:` and aligned with
  the same right-end column as Spelling/Tab Key/etc.
- View height tightened 450 → 370.

## Fonts & Colors pane

- New right-aligned `Search Highlight:` label added at the shared
  label column (ends at x=118 like Body Font and Max. Note Body
  Width); the existing checkbox's title flipped from `Search
  Highlight:` to `Highlight matches`.
- Color well moved to x=300 with `flexibleMaxX` so it doesn't drift
  off-screen on wide layouts.
- `Body Font:` label widened to start at x=8 (still ending at x=118)
  so it visually anchors at the same column as the new labels.
- `Body Font` field's `widthSizable` removed — it no longer grows
  past the `Set…` button.
- `Body Font` field's preview foreground switched from `blackColor` to
  `labelColor`, and its XIB background switched from literal white to
  the system-named `textBackgroundColor`, so it reads correctly in
  dark mode.
- `Max. Note Body Width:` label moved into the shared column (x=8,
  right-aligned); slider repositioned to start at x=121 with
  `widthSizable` so it grows with the window.
- The three boolean rows (`Always Show Grid Lines…`, `Alternating Row
  Colors`, `Keep Note Body Width Readable`) flipped from
  `imagePosition=right alignment=right` to standard
  `imagePosition=left alignment=left`, aligned at x=32, with the
  trailing colon dropped.

## Controller cleanup (`PrefsWindowController.{h,m}`)

- Removed outlets: `appShortcutField`, `tableTextMenuButton`,
  `togDockLabel`, `rtlButton`, `useReadabilityButton`,
  `readabilityHint`.
- Added outlet: `useLargeFontButton`.
- Removed actions: `setAppShortcut:`, `keyComboPanelEnded:`,
  `changedRTL:`, `changedUseReadability:`, the previous tag-driven
  `changedTableText:`.
- Added action: `changedListFontSize:`.
- Dropped `PTKeyComboPanel` / `PTKeyCombo` imports.

## Editor auto-link (component 17 follow-on; this commit also
includes it because it ships in the same workstream)

- `AttributedPlainText -addLinkAttributesForRange:` rewritten around
  `NSDataDetector` with `NSTextCheckingTypeLink`.
- `PreviewController +preprocessNVWikiLinks:` rewrites `[[Title]]` →
  `[Title](nvalt://find/Title)` before the Markdown processor sees
  the text.

## Files

- modified
  - `PrefsWindowController.h`
  - `PrefsWindowController.m`
  - `NotationPrefsViewController.m`
  - `en.lproj/Preferences.xib`
  - `en.lproj/NotationPrefsView.nib` (recompiled from XIB source)
- added
  - `NotationPrefsView.xib` (canonical XIB source for the Notes
    tabs, recompiled into the `.nib` bundle)
  - `docs/native-controls/18-prefs-polish.md` (earlier polish doc;
    kept for history)
  - `docs/superpowers/specs/2026-05-30-native-controls-18-prefs-polish-spec.md`
  - `docs/superpowers/specs/2026-05-31-native-controls-19-prefs-layout-mocks.md`

## Verification

- arm64 build succeeds (`** BUILD SUCCEEDED **`).
- App launches; Settings opens with `Settings` as the title and the
  four toolbar items (General, Notes, Editing, Fonts & Colors) on a
  dedicated row below it.
- All four panes render at the same 500pt width — window doesn't jump
  on tab switch.

## Reverting

`git revert <hash>` restores the prior pre-redesign layout. The
removed PTKeyCombo / Synchronization / RTL / Readability paths are
still in the codebase (only their UI hooks were removed), so a
revert restores the UI without recovering removed code.
