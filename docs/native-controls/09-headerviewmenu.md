# Native Controls 09 — Trim HeaderViewWithMenu

Companion to `docs/superpowers/specs/2026-05-30-native-controls-09-headerviewmenu-spec.md`.

## What changed

`HeaderViewWithMenu` is now a minimal `NSTableHeaderView` subclass
whose only override is `-menuForEvent:` (the legitimate reason to
subclass — building a per-column context menu). The two
problematic pieces are gone:

- The private-API override of `-_resizeColumn:withEvent:` is
  deleted. Apple has no obligation to keep that selector working;
  the override would crash with "unrecognized selector" if it ever
  disappeared.
- The `isReloading` cursor-rect hack is deleted. It existed to
  short-circuit `-resetCursorRects` during a reload — a workaround
  for cursor-rect cost that AppKit has long since batched. The
  `NotesTableView -reloadData` override that toggled the flag is
  also gone.

## How

Three small surgical edits:

- `HeaderViewWIthMenu.h` (filename-typo kept) collapsed to a
  one-method `@interface`.
- `HeaderViewWIthMenu.m` rewritten to ~20 lines: just
  `-menuForEvent:` that calls back into the table view's
  `menuForColumnConfiguration:`.
- `NotesTableView.m -reloadData` collapsed to a simple
  `[super reloadData]`.

## Files

- **modified**
  - `HeaderViewWIthMenu.h` — drop `isReloading` ivar and the
    `-setIsReloading:` declaration; add a doc comment describing
    what the subclass exists for.
  - `HeaderViewWIthMenu.m` — drop the `#import "NoteAttributeColumn.h"`,
    `-initWithFrame:`, `-setIsReloading:`, `-resetCursorRects`, and
    the `-_resizeColumn:withEvent:` override. Kept `-menuForEvent:`,
    simplified slightly.
  - `NotesTableView.m` — `-reloadData` no longer wraps the call in
    `setIsReloading:YES`/`:NO`.

## Verification

- arm64 build succeeds.
- App launches; right-clicking a notes-list column header still
  shows the *Columns* / *Sort By* context menu. Column resize works.

## Reverting

`git revert <hash>` restores the prior class and the
`reloadData` bracketing.

## Future cleanup (not in this commit)

The filename `HeaderViewWIthMenu.h/.m` carries a longstanding typo
(`WIth`). Renaming touches every importer and would change the
pbxproj entry; it's deferred to a dedicated rename pass.
