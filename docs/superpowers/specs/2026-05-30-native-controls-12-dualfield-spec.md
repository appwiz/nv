# Native Controls Migration 12 — DualField custom drawing → system bezel

Date: 2026-05-30
Status: spec
Component: `DualField` — the custom search/title field at the top of
the main window. The class is mostly application logic (snapback
chip, follow-link stack, title-vs-search bimodal behaviour, clear
button); a substantial chunk of `-drawRect:` is hand-painted chrome
that AppKit can supply for free.

## Scope (deliberately conservative)

Replacing `DualField` wholesale with `NSSearchField` is genuinely
hard: the field doubles as a note-title editor, the snapback chip is
non-standard, and the follow-link interaction is wired through this
class. Tearing that apart in one commit risks regressions that
can't be caught by a non-interactive smoke test.

This commit narrows the goal to *drop the hand-painted chrome and
use a system bezel*. The snapback chip, the clear button, the
document-icon swap, the title/search bimodal behaviour, and the
field-editor wiring all stay as-is. A future commit can revisit the
deeper restructure (`NSSearchField` accessory cells, separating the
title editor) if it proves worthwhile.

## Problem

`-drawRect:` does ~50 lines of hand work:

- Fills the field background with `NVAppearance.fieldBackgroundColor`.
- Draws two cap images (`DFCapLeftRounded` and `DFCapRight`, plus
  *Inactive* variants) for the rounded-left / squared-right ends.
- Strokes four 1-pt edges (top edge, top inner highlight, bottom
  edge, bottom highlight) with appearance-dependent grey values.
- Draws a custom `Pencil` or `Search` icon on the left.
- Lets the cell paint the text on top.
- Optionally draws a custom focus ring on pre-Yosemite (dead code
  under our 10.14 target).

The result mimics a 10.6 search field shape. On 10.14+ it looks
out of place — the rectangle has hand-strokes that don't match any
system control, and the cap images don't have dark-mode variants.

## Replacement

Use the system bezel:

- Set `[self setBordered:YES]` and
  `[self setBezelStyle:NSTextFieldRoundedBezel]` on `DualField` at
  `awakeFromNib`. AppKit draws an appearance-aware rounded field
  background and focus ring.
- Drop the `-drawRect:` override entirely.
- Drop the `BORDER_LEFT_OFFSET` / `BORDER_TOP_OFFSET` icon-placement
  constants and the document-icon images from `-drawRect:`. The
  document icon (Pencil / Search) becomes a `NSImageView` accessory
  positioned at the left edge of the field, added once at
  `awakeFromNib`, with its image swapped in
  `-setShowsDocumentIcon:`.
- Keep the cell's clear / snapback button drawing — those are in
  `DualFieldCell -drawWithFrame:` and run as part of the system
  field's text-painting pass, so the system bezel doesn't disturb
  them.
- Adjust `DualFieldCell`'s `textAreaForBounds:` (and the
  clear/snapback rect math) to account for the new system padding.
  The system rounded bezel has ~3 pt of leading inset; the icon
  accessory absorbs the rest.

## Files affected

- new: `docs/superpowers/specs/...-12-dualfield-spec.md`,
  `docs/native-controls/12-dualfield.md`.
- modified:
  - `DualField.h` — drop the `BORDER_LEFT_OFFSET` /
    `BORDER_TOP_OFFSET` defines (if any leaked into the header);
    no API change.
  - `DualField.m` — drop `-drawRect:`; add an `NSImageView`
    accessory in `-awakeFromNib`; swap its image in
    `-setShowsDocumentIcon:`. Trim the inset math in `DualFieldCell`
    so the text/clear/snapback positions line up with the system
    bezel.
  - `NVAppearance.h/.m` — remove
    `+fieldBackgroundColor` / `+fieldTextColor` (now unused; AppKit
    handles those for a bezeled NSTextField).
- not touched:
  - The cap image resources (`DFCapLeftRounded*`, `DFCapRight*`) — a
    separate asset-cleanup pass will scrub them.

## Risks / open questions

- The clear/snapback button rects are computed inside
  `DualFieldCell`'s `clearButtonRectForBounds:` and
  `snapbackButtonRectForBounds:` methods. They assume a flat field
  with the custom cap insets; a bezeled field's `cellFrame` will
  be slightly smaller. We'll inset the cell's `textAreaForBounds:`
  by the bezel's interior margin (≈ 3 pt left/right, 2 pt top/bottom
  for a rounded bezel) and confirm clear / snapback still
  hit-test correctly.
- The document-icon `NSImageView` placement gets its frame at
  `-awakeFromNib`; it's anchored to the left edge with
  `NSViewMaxXMargin` autoresize. Window resizes don't change the
  field origin, so that's stable.
- The custom focus-ring branch (`!IsYosemiteOrLater`) is dead at our
  deployment target; AppKit draws the system focus ring on a
  bezeled field automatically.

## Verification

- arm64 build succeeds.
- App launches; the field at the top of the window has a system
  rounded bezel, light/dark aware.
- Typing filters notes (search mode); clear button appears and
  works.
- Selecting a note populates the field with the title (title mode),
  the document icon switches to *Pencil*; editing the field renames
  the note.
- Following a wiki-style link shows the snapback chip; clicking it
  restores the previous query.
