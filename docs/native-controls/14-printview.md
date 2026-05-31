# Native Controls 14 — MultiplePageView → NSTextView print

Companion to `docs/superpowers/specs/2026-05-30-native-controls-14-printview-spec.md`.

## What changed

The 300-line `MultiplePageView` class (Apple TextEdit sample,
1995-2005) is replaced by a 40-line helper, `NVPrintRouter`, that
hands a single `NSTextView` to `NSPrintOperation` and lets AppKit
paginate.

## How

Modern `NSTextView` paginates itself during printing — when you
print a text view with a tall enough document, AppKit slices it
into pages of `paperSize - margins` automatically. The old class
predates that capability and hand-built the per-page layout:

- One `NSTextStorage` + one `NSLayoutManager`.
- A separate `NSTextContainer` + `NSTextView` per page.
- A pre-pass that allocated a throwaway view to *measure* how many
  pages a note's text occupies, then sized the parent view to the
  cumulative page count.
- A "force layout" by asking the layout manager for the text
  container of the last glyph.
- `-knowsPageRange:` and `-rectForPage:` overrides that returned
  hand-computed rects.

`NVPrintRouter` does none of that. It:

1. Builds a single `NSMutableAttributedString` by appending each
   note's `printableStringRelativeToBodyFont:` separated by a
   form-feed character (`\f`, same as `NSFormFeedCharacter`).
2. Allocates one `NSTextView` sized to `paperSize - margins` from
   `[NSPrintInfo sharedPrintInfo]`.
3. Sets its `textStorage` and hands it to
   `[NSPrintOperation printOperationWithView:printInfo:]`.
4. Runs the operation modal for the window.

Each note still starts on a new page because the form-feeds force a
page break, exactly like before.

## Files

- **new**
  - `NVPrintRouter.h`, `NVPrintRouter.m`.
  - `docs/native-controls/14-printview.md`,
    `docs/superpowers/specs/2026-05-30-native-controls-14-printview-spec.md`.
- **modified**
  - `AppController.m` — swap `#import "MultiplePageView.h"` for
    `#import "NVPrintRouter.h"`; swap the single call site from
    `[MultiplePageView printNotes:forWindow:]` to
    `[NVPrintRouter printNotes:forWindow:]`.
  - `Notation.xcodeproj/project.pbxproj` — add NVPrintRouter
    entries; remove the MultiplePageView entries.
- **deleted**
  - `MultiplePageView.h`, `MultiplePageView.m`.

## Verification

- arm64 build succeeds.
- App launches.
- Manual smoke check (after this pulls): `File → Print` on a
  multi-note selection. Each note appears on its own page; standard
  system print sheet; system page-range UI works.

## Reverting

`git revert <hash>` restores both deleted files, removes
NVPrintRouter, and brings back the prior call site.
