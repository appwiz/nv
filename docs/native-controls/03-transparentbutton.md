# Native Controls 03 — ETTransparentButton → NSButton

Companion to `docs/superpowers/specs/2026-05-30-native-controls-03-transparentbutton-spec.md`.

## What changed

The three buttons inside the Markdown Preview share popovers
(*Yes*, *No, thanks*, *View in Browser*) are now plain `NSButton`s
with the system push-button bezel.

## How

In the previous shape the popover (then a `MAAttachedWindow`) had a
near-black background, so `ETTransparentButton` cells drew their own
transparent surface to blend in. After Component 1 the popovers use
`NSPopover`'s system materials, and a transparent-on-blur button
looks unstyled rather than intentional. Switching to a stock
`NSButton` with `NSBezelStylePush` gives:

- AppKit-managed sizing, font, focus ring, and accent tint;
- system-native dark / light appearance with no app-side colors;
- proper default-button rendering on *Yes* (key equivalent `\r`) so
  Enter activates it without an explicit key handler;
- Escape cancels *No, thanks* via key equivalent `\e`.

The `NSBezelStylePushButton` constant was renamed `NSBezelStylePush`
in modern AppKit (macOS 14+); the new code uses the current name and
relies on the system's deprecation shim for the old one if other
files reference it.

## Files

- **`PreviewController.h`**
  - dropped `@class ETTransparentButton;`.
  - changed three ivar types from `ETTransparentButton *` to
    `NSButton *`: `shareConfirm`, `shareCancel`, `viewOnWebButton`.
- **`PreviewController.m`**
  - dropped `#import "ETTransparentButton.h"` and
    `#import "ETTransparentButtonCell.h"`.
  - replaced the three `[[ETTransparentButton alloc] initWithFrame:]`
    allocations with `[[NSButton alloc] initWithFrame:]` and a
    `setBezelStyle:NSBezelStylePush` call each.
  - added `setKeyEquivalent:@"\r"` on *Yes* (default) and
    `setKeyEquivalent:@"\e"` on *No, thanks* (cancel).
- **`Notation.xcodeproj/project.pbxproj`**
  - removed the four entries (two PBXBuildFile, four
    PBXFileReference, four group, two Sources) for
    `ETTransparentButton.{h,m}` and `ETTransparentButtonCell.{h,m}`.
- **deleted**: `ETTransparentButton.h`, `ETTransparentButton.m`,
  `ETTransparentButtonCell.h`, `ETTransparentButtonCell.m`.

## Verification

- arm64 build succeeds.
- App launches; share popover shows two system push buttons; Enter
  triggers *Yes*, Escape cancels.

## Reverting

`git revert <hash>` restores the four files and the original
PreviewController code.
