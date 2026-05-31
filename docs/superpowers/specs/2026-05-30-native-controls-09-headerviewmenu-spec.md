# Native Controls Migration 09 — Trim HeaderViewWithMenu

Date: 2026-05-30
Status: spec
Component: `HeaderViewWithMenu` — an `NSTableHeaderView` subclass
used by `NotesTableView` to provide a right-click context menu on
column headers.

## Problem

The class is mostly fine — providing a context menu through
`-menuForEvent:` is the documented way to add one to a custom view.
But two pieces are problematic:

1. **Private API override.** The class overrides
   `-_resizeColumn:withEvent:`, an undocumented internal
   `NSTableHeaderView` method. The override tweaks the column
   resizing mask momentarily to coax a different resize behaviour,
   then schedules a deferred reset to the original mask. If Apple
   renames or removes that selector — or changes its arguments —
   the app crashes with "unrecognized selector". Modern AppKit also
   provides public alternatives (set `resizingMask` on the columns
   directly) so this hack isn't earning its keep.

2. **`isReloading` cursor-rect hack.** `NotesTableView -reloadData`
   sets `headerView.isReloading = YES` before calling
   `[super reloadData]` and back to `NO` after, and
   `HeaderViewWithMenu -resetCursorRects` short-circuits if the
   flag is set. This was a workaround for old behaviour where
   reloads triggered expensive per-column cursor-rect
   recomputation. Modern AppKit batches cursor-rect invalidations,
   so the override is paying overhead for a problem that no longer
   exists.

## Approach

1. Drop the `-_resizeColumn:withEvent:` override entirely.
2. Drop the `isReloading` ivar, the `-setIsReloading:` setter, the
   `-resetCursorRects` override, and the `headerView.isReloading`
   bracketing in `NotesTableView -reloadData`.
3. Keep the `-menuForEvent:` override — that's the legitimate
   subclass justification.
4. Remove the unused `#import "NoteAttributeColumn.h"` from
   `HeaderViewWithMenu.m` (it was needed only for the
   `setResizingMask:` calls inside the dropped private override).

## Files affected

- new: `docs/superpowers/specs/...-09-headerviewmenu-spec.md`,
  `docs/native-controls/09-headerviewmenu.md`.
- modified:
  - `HeaderViewWIthMenu.h` (note the historical typo in the
    filename — kept as-is to avoid an irrelevant per-locale NIB
    re-archive; the class name spelled correctly).
  - `HeaderViewWIthMenu.m`.
  - `NotesTableView.m`.

## Risks / open questions

- Removing the resize-mask hack means column resizes use the system
  default behaviour from now on. If users have come to rely on the
  bespoke behaviour, this is observable; in practice both behaviours
  feel similar.

## Verification

- arm64 build succeeds.
- Right-click on a notes-list column header still shows the
  context menu with *Columns* and *Sort By* submenus.
- Column resizing still works.
- `reloadData` still works (no crash, no flicker).
