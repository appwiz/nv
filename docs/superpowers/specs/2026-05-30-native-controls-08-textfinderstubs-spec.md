# Native Controls Migration 08 — Drop pre-Lion text-finder stubs

Date: 2026-05-30
Status: spec
Component: `MultiTextFinder.{h,m}`, `NSTextFinder.h`,
`NSTextFinder_LastFind.m` — stubs that supported a pre-Lion find
panel.

## Problem

Three files survive from before AppKit shipped `NSTextFinder`
(10.7). At our 10.14 deployment target they are either preprocessed
out or never reached:

- **`MultiTextFinder.h/.m`** — The whole implementation is wrapped
  in `#if MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_7`. On
  the macOS 26.5 SDK the conditional is false, so the file compiles
  to an empty translation unit.

- **`NSTextFinder.h`** — Every line in the file is a `//`-prefixed
  comment. It's a record of an old class-dump of the private
  AppKit `NSTextFinder` class from 10.4 / 10.6, kept for reference
  during the pre-Lion fallback's lifetime.

- **`NSTextFinder_LastFind.m`** — A category on `NSTextFinder` that
  adds `-nv_lastFindWasSuccessful`, which reads a private ivar via
  KVC. Nothing calls it (`grep -n nv_lastFindWasSuccessful` returns
  only the definition itself and the commented declaration in
  `NSTextFinder.h`).

`LinkingEditor.m` is the live find consumer. It uses the public
`NSTextFinder` class directly (via `+sharedTextFinder` and
`-performAction:`); none of the three files above factor into that
path.

## Approach

1. Delete `MultiTextFinder.h`, `MultiTextFinder.m`,
   `NSTextFinder.h`, `NSTextFinder_LastFind.m`.
2. Strip the pbxproj entries for the four files
   (`MultiTextFinder.{h,m}`: PBXFileReference + PBXBuildFile + group
   + Sources; `NSTextFinder.h`: PBXFileReference + group;
   `NSTextFinder_LastFind.m`: PBXBuildFile + PBXFileReference + group
   + Sources).
3. Sanity-check `LinkingEditor.m` doesn't import any of the deleted
   headers (it doesn't — the live code is `#import` of
   `<Cocoa/Cocoa.h>` via the system path, not the local class-dump).

## Files affected

- new: `docs/superpowers/specs/...-08-textfinderstubs-spec.md`,
  `docs/native-controls/08-textfinderstubs.md`.
- modified: `Notation.xcodeproj/project.pbxproj`.
- deleted: `MultiTextFinder.h`, `MultiTextFinder.m`,
  `NSTextFinder.h`, `NSTextFinder_LastFind.m`.

## Verification

- arm64 build succeeds.
- ⌘F in the editor still opens the system find bar; next / previous
  / replace work.
