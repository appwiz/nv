# Native Controls 12 — DualField (deferred)

Status: **deferred**. Spec written, no code change in this commit.

## Why deferred

`DualField` is a single class doing several jobs:

1. Top-of-window search field (typing filters notes).
2. Note title editor (selecting a note populates and edits its
   title in the same field).
3. Snapback chip (orange pill showing the originating query when
   the user has followed a wiki-style link, click to restore).
4. Clear button.
5. Document-icon swap (`Pencil` ↔ `Search`).
6. Follow-link history stack.

The drawing of (3)-(5) lives in `DualFieldCell -drawWithFrame:`,
where button rects are computed from `BORDER_LEFT_OFFSET` /
`BORDER_TOP_OFFSET` constants and the field's bounds. The custom
`DualField -drawRect:` paints chrome (`DFCapLeftRounded`,
`DFCapRight`, four edge strokes, background fill) that the cell
math is implicitly calibrated against.

Swapping `DualField` to a bezeled `NSTextField` (or `NSSearchField`)
moves the active text area inward by the system bezel's interior
margin (~3 pt). Without retuning the cell's rect math, the clear
and snapback buttons land in the wrong place — often clipped by the
bezel.

Verifying the retune requires interactive testing the three
behaviour modes — search, title editing, snapback follow-link — none
of which I can drive without a UI test framework or hands on the
trackpad. The risk of shipping a subtle hit-test regression
(e.g. clear button works in search mode but not after a snapback)
is higher than for the other components migrated in this batch.

## Spec

See `docs/superpowers/specs/2026-05-30-native-controls-12-dualfield-spec.md`.
The spec describes the conservative path (system rounded bezel +
NSImageView accessory for the document icon + cell rect retune) and
the more ambitious path (full `NSSearchField` replacement with
accessory cells).

## Recommended approach when picked up

Do this with the app running and the dev loop tight:

1. Apply the spec's conservative change.
2. Test all three modes manually:
   - Search: type, watch results filter, hit clear, watch results
     unfilter.
   - Title edit: select a note, rename it, commit.
   - Snapback: follow a `[[wiki link]]`, click the snapback chip,
     verify the original query returns.
3. If clear / snapback land outside the visible field, adjust the
   `textAreaForBounds:` / `clearButtonRectForBounds:` /
   `snapbackButtonRectForBounds:` insets one at a time, smoke
   testing each.

## State on disk after this commit

The spec and this deferral note are committed. The `DualField`
source is unchanged.
