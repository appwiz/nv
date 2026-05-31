# Native Controls Migration 05 — Drop NotesTableCornerView

Date: 2026-05-30
Status: spec
Component: `NotesTableCornerView` (custom `NSView` subclass that was
to be the notes-list table's top-right corner view).

## Problem

The class exists on disk, but it is not wired into anything:

- The `#import "NotesTableCornerView.h"` in `NotesTableView.m` is
  already commented out.
- `NotesTableView` actively sets the corner view to `nil` at init
  (line 108 and 469): `[self setCornerView:nil];`.
- The class is not present in `Notation.xcodeproj/project.pbxproj`,
  so it isn't even compiled into the binary.

It's a leftover. We also kept it themed in
`NVAppearance` (`tableCornerFillColor`, `tableCornerBorderColor`)
during the dark-mode pass; both accessors are unused.

There is also a stale `[[notesTableView cornerView] setNeedsDisplay:YES]`
call in `AppController.m -updateColorScheme`. Since the table's
corner view is `nil`, this is a message to nil — a silent no-op.

## Approach

1. Delete `NotesTableCornerView.h` and `NotesTableCornerView.m`.
2. Drop the now-dead `[[notesTableView cornerView] setNeedsDisplay:YES]`
   line from `AppController.m`.
3. Drop the unused `+tableCornerFillColor` and
   `+tableCornerBorderColor` accessors from `NVAppearance.h/.m`.
4. No XIB or pbxproj changes needed (the class isn't referenced in
   either).

## Files affected

- new: `docs/superpowers/specs/...-05-cornerview-spec.md`,
  `docs/native-controls/05-cornerview.md`.
- modified: `AppController.m`, `NVAppearance.h`, `NVAppearance.m`.
- deleted: `NotesTableCornerView.h`, `NotesTableCornerView.m`.

## Verification

- arm64 build succeeds.
- App launches; nothing visually changes (the corner view was
  already `nil` at runtime).
