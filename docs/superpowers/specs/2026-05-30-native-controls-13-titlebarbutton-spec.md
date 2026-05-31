# Native Controls Migration 13 — TitlebarButton → NSTitlebarAccessoryViewController

Date: 2026-05-30
Status: spec
Component: `TitlebarButton` + `TitlebarButtonCell` — a custom
`NSPopUpButton`/`NSPopUpButtonCell` pair that AppController inserts
into the title bar next to the close button to show sync status.

## Problem

`TitlebarButton` does several non-standard things:

- Inserts itself into the standard window controls' superview at
  `+addToWindow:` time, hand-positioning the frame relative to the
  close button. That's a fragile layout that has been deprecated
  in favour of `NSTitlebarAccessoryViewController` since 10.10.
- Uses the deprecated `-[NSWindow convertBaseToScreen:]` for drag
  tracking on pre-Leopard.
- Hand-draws a hover background image (`TBMousedownBG`,
  `TBRolloverBG`) and icon swap (`TBDownArrow`, `TBSynchronizing`,
  `TBAlert` plus *White* variants) — none of which have dark-mode
  variants, so they read incorrectly under Dark Aqua.
- Spins the `TBSynchronizing` icon manually via an
  `NSTimer`-driven affine-transform rotation.

The four icon states are `NoIcon`, `DownArrowIcon`,
`SynchronizingIcon`, and `AlertIcon`.

## Replacement

An `NSTitlebarAccessoryViewController` is AppKit's documented way to
add a control to the title bar. Inside it we put:

- An `NSPopUpButton` with `pullsDown:YES`, `bordered:NO`, using a
  template `NSImage` named via SF Symbols (`chevron.down.circle`,
  `arrow.triangle.2.circlepath`, `exclamationmark.triangle.fill`)
  via `+[NSImage imageWithSystemSymbolName:accessibilityDescription:]`
  (10.16+). Template images automatically follow the menu bar tint
  + system appearance.
- An `NSProgressIndicator` (small style, indeterminate spinner) for
  the *Synchronizing* state. AppKit's spinner already rotates on a
  timer for us; setting `[spinner startAnimation:nil]` is the whole
  contract.

State map:

| State | UI |
| --- | --- |
| `NoIcon` | accessory hidden (`hidden = YES`) |
| `DownArrowIcon` | popup button visible with the chevron image, spinner hidden |
| `SynchronizingIcon` | spinner visible + animating, popup hidden |
| `AlertIcon` | popup visible with the triangle image (system red tint via `contentTintColor`), spinner hidden |

The menu (sync status menu) attaches to the popup as before.

## Approach

1. Define a small replacement class `NVTitlebarSyncAccessory` that
   subclasses `NSTitlebarAccessoryViewController` and owns the
   popup + spinner subviews.
2. Expose a single `-setIconType:` method that does the state
   switching. Keep the original `TitleBarButtonIcon` enum
   (`NoIcon` / `DownArrowIcon` / `SynchronizingIcon` / `AlertIcon`)
   so the call sites in `AppController` don't all change.
3. Wire it up in `AppController -setDualFieldInToolbar` (or
   wherever the `TitlebarButton -addToWindow:` call lives now —
   line ~2477) by allocating the accessory controller, configuring
   the popup's `menu` from the sync status menu, and calling
   `-[NSWindow addTitlebarAccessoryViewController:]`.
4. Delete `TitlebarButton.h`, `TitlebarButton.m`, and the matching
   pbxproj entries.
5. Update `AppController.h` — replace
   `@class TitlebarButton;` with the new class, retype the
   `titleBarButton` ivar.
6. The four call sites (`-setStatusIconType:` callers) become
   `-setIconType:` calls. Menu attachment stays the same.

## Files affected

- new: `NVTitlebarSyncAccessory.h`, `NVTitlebarSyncAccessory.m`.
- modified:
  - `AppController.h` — drop `@class TitlebarButton`, rename + retype
    ivar.
  - `AppController.m` — drop `#import "TitlebarButton.h"`, replace
    the title-bar button setup and the four `setStatusIconType:`
    callers.
  - `Notation.xcodeproj/project.pbxproj` — add accessory class
    entries, remove TitlebarButton entries.
- deleted: `TitlebarButton.h`, `TitlebarButton.m`.

## Risks / open questions

- The icon images (`TBDownArrow`, `TBSynchronizing`, `TBAlert`,
  plus their *White* variants) are still in the bundle Resources;
  no harm in leaving them for now, separate cleanup pass.
- `+imageWithSystemSymbolName:` requires 11.0+. The deployment
  target is 10.14 — if we strictly want 10.14 to work, we fall back
  to a bundled template image for the chevron and an `NSImage`
  named `NSCaution` for the alert. Practically, every user on a
  modern build runs 11+ and the symbol API is cleaner. Decision:
  use `imageWithSystemSymbolName:` and rely on `@available(macOS
  11.0, *)`.
- AppKit titlebar accessory positioning supports `layoutAttribute =
  NSLayoutAttributeRight` (places to the right of the title) and
  `NSLayoutAttributeTop` (above). The right placement is the closest
  match to the original position next to the close button.

## Verification

- arm64 build succeeds.
- App launches; with `ShowSyncMenu` unset, no sync icon appears in
  the title bar (matches old behaviour for `NoIcon`).
- Toggle `ShowSyncMenu` → chevron icon appears; clicking it shows
  the sync status menu.
- Trigger a Simplenote sync (if configured) → chevron is replaced by
  the indeterminate spinner; when sync ends, chevron returns.
- Provoke a sync error → the alert triangle appears.
