# Native Controls 08 — Drop pre-Lion text-finder stubs

Companion to `docs/superpowers/specs/2026-05-30-native-controls-08-textfinderstubs-spec.md`.

## What changed

Four files that supported a pre-Lion fallback find panel are
deleted. They were either preprocessed out (the
`MAC_OS_X_VERSION_MAX_ALLOWED < 10.7` gate) or never referenced
under our deployment target.

| File | Why dead |
| --- | --- |
| `MultiTextFinder.h`, `MultiTextFinder.m` | `#if MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_7` wraps the whole file. On the 26.5 SDK the conditional is false; the .m compiles to nothing. |
| `NSTextFinder.h` | Every non-empty line is `//`-prefixed. The file was a record of a class-dump of the private 10.4 / 10.6 `NSTextFinder` ivar layout, kept for reference. Public `NSTextFinder` is now the documented AppKit class. |
| `NSTextFinder_LastFind.m` | A category on `NSTextFinder` adding `-nv_lastFindWasSuccessful` (KVC-pokes a private ivar). Never called; never even added to the build phase. |

`LinkingEditor.m` is the live find-bar consumer. It uses the public
`NSTextFinder` directly (`+sharedTextFinder`, `-performAction:`,
`NSTextFinderActionShowFindInterface`, …) and never touched any of
the deleted files.

## How

Pure deletion. Strip the matching entries from
`Notation.xcodeproj/project.pbxproj` for `MultiTextFinder.{h,m}` and
`NSTextFinder.h`. (`NSTextFinder_LastFind.m` had no pbxproj entry.)

## Files

- **deleted (4)**
  - `MultiTextFinder.h`, `MultiTextFinder.m`
  - `NSTextFinder.h`
  - `NSTextFinder_LastFind.m`
- **modified**
  - `Notation.xcodeproj/project.pbxproj` — stripped six lines (two
    PBXBuildFile, three PBXFileReference, three group / one Sources).

## Verification

- arm64 build succeeds.
- App launches; ⌘F in the editor still shows the system find bar,
  and next / previous / replace / hide actions work.

## Reverting

`git revert <hash>` restores all four files and the pbxproj
entries.
