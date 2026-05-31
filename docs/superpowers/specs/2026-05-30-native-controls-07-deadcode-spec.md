# Native Controls Migration 07 — Delete dead source files

Date: 2026-05-30
Status: spec
Component: orphan source files left over from earlier features.

## Problem

Seven `.h/.m` pairs sit in the repository but have no references
anywhere — no other source file imports them, no XIB or compiled NIB
mentions them, and most of them aren't even compiled (no
PBXBuildFile entry). Carrying them slows down navigation, dilutes
"what does this app actually use" answers, and creates ambiguity
about what's authoritative.

The classes:

| File | Subclass of | Status |
| --- | --- | --- |
| `CustomTextFieldCell` | `NSTextFieldCell` | not built, not used |
| `FocusRingScrollView` | `NSScrollView` | not built, not used |
| `FullscreenWindow` | `NSWindow` | not built, not used |
| `GGReadabilityParser` | `NSObject` | not built, not used |
| `LabelEditor` | (NS variant) | not built, not used |
| `QuickSearchTable` | (NS variant) | not built, not used |
| `StatusItemView` | `NSView` | listed in the *disabled/old classes* group only |

Verification: `grep -rn` across `*.m`, `*.h`, `*.xib`,
`*.lproj/*.xib`, `*.lproj/*.nib/keyedobjects.nib` (via `plutil
-convert xml1`) returns zero hits for every name except the file
itself.

## Replacement

None — pure deletion.

## Approach

1. `rm` the fourteen files from disk.
2. Strip the `StatusItemView` entries from
   `Notation.xcodeproj/project.pbxproj` (PBXFileReference pair and
   PBXGroup membership in the *disabled/old classes* group).
3. The other six classes have no pbxproj entries, so deletion is
   purely a filesystem change for them.

## Files affected

- new: `docs/superpowers/specs/...-07-deadcode-spec.md`,
  `docs/native-controls/07-deadcode.md`.
- modified: `Notation.xcodeproj/project.pbxproj`.
- deleted: 14 files
  (`CustomTextFieldCell.{h,m}`, `FocusRingScrollView.{h,m}`,
  `FullscreenWindow.{h,m}`, `GGReadabilityParser.{h,m}`,
  `LabelEditor.{h,m}`, `QuickSearchTable.{h,m}`,
  `StatusItemView.{h,m}`).

## Verification

- arm64 build succeeds.
- App launches; nothing user-visible changes (the deleted files were
  never executed).
