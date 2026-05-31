# Native Controls Migration 14 — MultiplePageView → NSTextView print

Date: 2026-05-30
Status: spec
Component: `MultiplePageView` — a 300-line `NSView` subclass derived
from Apple's 1995-2005 TextEdit sample code, used solely to print a
selection of notes.

## Problem

`MultiplePageView` predates `NSTextView`'s built-in pagination. It
hand-rolls a layout:

- One `NSTextStorage` + one `NSLayoutManager`.
- A separate `NSTextContainer` and `NSTextView` for every printed
  page.
- A pre-pass that creates a throwaway text view to measure how many
  pages a piece of text occupies, so it can size the parent view to
  the total page count.
- Form-feed characters between notes to force page breaks.
- A manual "force layout" by querying the layout manager for a glyph
  range — required because the per-page text containers must be
  laid out before printing.
- `-knowsPageRange:` / `-rectForPage:` overrides that return the
  hand-computed per-page rectangles.

Modern `NSTextView` paginates itself when printed: feed a single
text view the document, hand it to `NSPrintOperation`, and AppKit
handles container slicing, headers/footers, page rects, and layout.
The 300 lines of hand-rolled math are obsolete.

## Replacement

`+printNotes:forWindow:` becomes a small helper:

1. Build a single `NSMutableAttributedString` by concatenating each
   selected note's `printableStringRelativeToBodyFont:`, separated
   by a form-feed (so each note starts on a new page, matching the
   prior behaviour).
2. Allocate an `NSTextView` sized to the current `NSPrintInfo`'s
   paper size minus margins.
3. Set its `textStorage` to the concatenated string.
4. Hand it to `[NSPrintOperation printOperationWithView:printInfo:]`
   and run modal for the window.

Everything else — pagination, header/footer space, scaling, page
range UI, "print selection / range" — comes from `NSPrintOperation`
+ `NSTextView` for free.

## Approach

1. Delete `MultiplePageView.h` and `MultiplePageView.m`.
2. Move `+printNotes:forWindow:` into a small new helper class
   `NVPrintRouter` (no view subclass — just a class method). Or fold
   the helper directly into AppController as a private method.
   Decision: keep it as a helper class so it can be tested
   independently and so the AppController file doesn't grow.
3. The two existing call sites are:
   - `AppController.m:949` — `[MultiplePageView printNotes:[...] forWindow:window]`
   - `AppController.m:41` — `#import "MultiplePageView.h"`
   Update both to use the helper.
4. Remove the pbxproj entries for `MultiplePageView`.

## Files affected

- new:
  - `NVPrintRouter.h`, `NVPrintRouter.m`.
  - `docs/superpowers/specs/...-14-printview-spec.md`,
    `docs/native-controls/14-printview.md`.
- modified:
  - `AppController.h/m` — swap import, swap the one call site.
  - `Notation.xcodeproj/project.pbxproj` — add NVPrintRouter
    entries, remove MultiplePageView entries.
- deleted: `MultiplePageView.h`, `MultiplePageView.m`.

## Risks

- The hand-rolled implementation used `NSPrintInfo`'s margins via
  the `documentSizeInPage` / `documentRectForPageNumber:` methods on
  `MultiplePageView`. `NSPrintOperation -printOperationWithView:`
  also honours `NSPrintInfo` margins automatically; the result will
  look the same.
- Page numbers in headers/footers — the original implementation
  doesn't draw page numbers or headers either (the comment in
  `printableViewWithNotes:` says "add per-page header/footers here"
  with no implementation). Behaviour unchanged.

## Verification

- arm64 build succeeds.
- File > Print on a selection of notes shows the standard system
  print sheet. Each note starts on a new page.
