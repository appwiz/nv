# Native Controls 04 — NotesTableHeaderCell → NSTableHeaderCell

Companion to `docs/superpowers/specs/2026-05-30-native-controls-04-tableheader-spec.md`.

## What changed

The notes list now uses the stock `NSTableHeaderCell` for its column
headers. The custom `NotesTableHeaderCell` subclass is deleted, and
the unused `BTTableHeaderCell` class is removed at the same time.

## How

The previous `NotesTableHeaderCell` overrode three things —
`-drawWithFrame:inView:`, `-highlight:withFrame:inView:`, and a
small `+setTxtColor:` / `+setBColor:` static-color cache. After the
dark-mode pass the overrides had collapsed to a flat fill from
`NVAppearance` + a column-separator stroke. The system
`NSTableHeaderCell` already renders an appearance-aware header with
text, sort indicator, and click highlight; the custom version was
duplicating that work without adding visual value.

`NotesTableView.m` now allocates the column header as
`[[[NSTableHeaderCell alloc] initTextCell:title] autorelease]`. Two
no-op call sites that fed the class-level color setters
(`AppController -updateColorScheme`, `NotesTableView -setBackgroundColor:`)
are removed.

`BTTableHeaderCell` was never wired into the build, never imported,
and never referenced from any XIB. It comes out as part of the same
cleanup.

## Files

- **modified**
  - `NotesTableView.m`
    - dropped `#import "NotesTableHeaderCell.h"`.
    - column-header allocation switched from `NotesTableHeaderCell`
      to `NSTableHeaderCell`.
    - removed `[NotesTableHeaderCell setBColor:color]` in
      `-setBackgroundColor:`.
  - `AppController.m`
    - dropped `#import "NotesTableHeaderCell.h"`.
    - removed `[NotesTableHeaderCell setTxtColor:...]` from
      `-updateColorScheme`.
  - `Notation.xcodeproj/project.pbxproj`
    - removed the four entries (PBXBuildFile, PBXFileReference,
      group, Sources) for `NotesTableHeaderCell.{h,m}`.

- **deleted**
  - `NotesTableHeaderCell.h`, `NotesTableHeaderCell.m`.
  - `BTTableHeaderCell.h`, `BTTableHeaderCell.m` (was already not
    in the build; removed as orphan).

## Verification

- arm64 build succeeds.
- App launches; the notes-list column header renders as a standard
  macOS table header in both light and dark mode. Click-to-sort still
  works.

## Reverting

`git revert <hash>` restores the deleted files and the prior code.
