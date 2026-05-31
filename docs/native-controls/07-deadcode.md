# Native Controls 07 — Delete dead source files

Companion to `docs/superpowers/specs/2026-05-30-native-controls-07-deadcode-spec.md`.

## What changed

Fourteen orphan source files — seven `.h`/`.m` pairs — are deleted.
They were not compiled into the binary, not referenced by any
imported header, and not mentioned in any XIB or compiled NIB.

| Class | Origin |
| --- | --- |
| `CustomTextFieldCell` | leftover from an early control-panel experiment |
| `FocusRingScrollView` | predecessor to the current scroll-view setup |
| `FullscreenWindow` | early full-screen window subclass; superseded by AppKit's full-screen support |
| `GGReadabilityParser` | third-party DOM-parser dropped when Readability was removed from the importer |
| `LabelEditor` | an old per-row label edit popup |
| `QuickSearchTable` | a pre-`NotesTableView` table subclass |
| `StatusItemView` | a custom menu-bar item view (never wired in; the modern code uses `NSStatusItem.button` with a template image) |

## How

`rm` the files. The only project metadata edit was to strip the
`StatusItemView` PBXFileReference and group-membership entries from
`Notation.xcodeproj/project.pbxproj`, which kept the class visible
in the *disabled/old classes* group of the Xcode source navigator
even though it wasn't built.

## Files

- **deleted (14)**
  - `CustomTextFieldCell.h`, `CustomTextFieldCell.m`
  - `FocusRingScrollView.h`, `FocusRingScrollView.m`
  - `FullscreenWindow.h`, `FullscreenWindow.m`
  - `GGReadabilityParser.h`, `GGReadabilityParser.m`
  - `LabelEditor.h`, `LabelEditor.m`
  - `QuickSearchTable.h`, `QuickSearchTable.m`
  - `StatusItemView.h`, `StatusItemView.m`
- **modified**
  - `Notation.xcodeproj/project.pbxproj` — removed the four
    `StatusItemView` entries.

## Verification

- arm64 build succeeds.
- App launches; no behavioural or visual change (these files were
  never executed).

## Reverting

`git revert <hash>` restores all 14 files and the pbxproj entries.
