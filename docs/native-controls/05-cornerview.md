# Native Controls 05 — Drop NotesTableCornerView

Companion to `docs/superpowers/specs/2026-05-30-native-controls-05-cornerview-spec.md`.

## What changed

`NotesTableCornerView` is deleted. The class was already a no-op at
runtime — it wasn't compiled into the binary (no pbxproj entry), and
`NotesTableView` actively assigns `setCornerView:nil` at init. We
also drop the two `NVAppearance` accessors that only the dead class
called, and a stale `[[notesTableView cornerView] setNeedsDisplay:YES]`
line in `AppController.m -updateColorScheme` that was messaging nil.

## How

Pure cleanup. Nothing user-visible changes — the corner is `nil`
before and after.

## Files

- **modified**
  - `AppController.m` — dropped the `cornerView` redraw line in
    `-updateColorScheme`.
  - `NVAppearance.h` / `NVAppearance.m` — removed
    `+tableCornerFillColor` and `+tableCornerBorderColor`.
- **deleted**
  - `NotesTableCornerView.h`, `NotesTableCornerView.m`.

## Verification

- arm64 build succeeds.
- App launches; no behavioural or visual change.

## Reverting

`git revert <hash>` restores both files and the dropped methods.
