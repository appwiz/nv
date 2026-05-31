# Native Controls Migration 04 — NotesTableHeaderCell → NSTableHeaderCell

Date: 2026-05-30
Status: spec
Component: `NotesTableHeaderCell` (custom `NSTableHeaderCell`
subclass for the notes-list table header). Also drops the dead
`BTTableHeaderCell` class.

## Problem

`NotesTableHeaderCell` was originally a heavily-themed header cell
(custom gradient fill, custom border, static text/background colors
maintained via `+setBColor:` / `+setTxtColor:` class methods). After
the dark-mode pass it was already trimmed to:

- flat fill drawn from `NVAppearance.tableHeaderBackgroundColor`,
- bottom + column-separator border drawn from
  `NVAppearance.tableGridColor`,
- 6×1 inset on the text drawing rect,
- minor sort-indicator y-offset (1 px).

`NSTableHeaderCell` (since 10.10) already renders an appearance-aware
header. The custom class isn't earning its keep — the only deltas are
cosmetic and not worth the maintenance.

`BTTableHeaderCell` is a separate custom header-cell class that
isn't referenced anywhere or compiled into the project — it's dead
code.

## Replacement

Use `NSTableHeaderCell` directly. Delete `NotesTableHeaderCell` and
`BTTableHeaderCell`. AppKit's header handles:

- fill / border styling per appearance,
- sort indicator,
- text drawing with the right system font and color,
- highlight on click.

## Approach

1. In `NotesTableView.m` change the column header allocation from
   `[[[NotesTableHeaderCell alloc] initTextCell:...]] autorelease]`
   to `[[[NSTableHeaderCell alloc] initTextCell:...]] autorelease]`.
2. Drop `[NotesTableHeaderCell setBColor:color]` in
   `NotesTableView.m`'s `-setBackgroundColor:` override (it was a
   no-op already).
3. Drop `[NotesTableHeaderCell setTxtColor:...]` in
   `AppController.m`'s `-updateColorScheme` (also a no-op).
4. Remove `#import "NotesTableHeaderCell.h"` from `NotesTableView.m`
   and `AppController.m`.
5. Delete `NotesTableHeaderCell.{h,m}` and `BTTableHeaderCell.{h,m}`
   from disk.
6. Strip pbxproj entries for `NotesTableHeaderCell.{h,m}`
   (`BTTableHeaderCell` isn't in the build).

## Files affected

- new: `docs/superpowers/specs/...-04-tableheader-spec.md`,
  `docs/native-controls/04-tableheader.md`.
- modified: `NotesTableView.m`, `AppController.m`,
  `Notation.xcodeproj/project.pbxproj`.
- deleted: `NotesTableHeaderCell.h`, `NotesTableHeaderCell.m`,
  `BTTableHeaderCell.h`, `BTTableHeaderCell.m`.

## Risks / open questions

- Visual change: header text inset moves by a couple of points and
  the column separator look becomes the system default. Acceptable.
- The static class-level color setters were already no-ops, so
  removing them changes nothing at runtime.

## Verification

- arm64 build succeeds.
- App launches; the notes-list column header looks like a standard
  macOS table header in both light and dark mode; sorting still
  works.
