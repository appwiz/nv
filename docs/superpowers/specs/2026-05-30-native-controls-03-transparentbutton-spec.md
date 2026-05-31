# Native Controls Migration 03 — ETTransparentButton → NSButton

Date: 2026-05-30
Status: spec
Component: `ETTransparentButton` / `ETTransparentButtonCell` — a
hand-drawn transparent push button shipped with the project and
used only inside the Markdown Preview's share popovers.

## Problem

`PreviewController` builds three buttons in code and adds them as
subviews of the share popover content views:

- `shareConfirm` — *Yes*, primary action.
- `shareCancel` — *No, thanks*, secondary action.
- `viewOnWebButton` — *View in Browser*.

All three are `ETTransparentButton`s. The class draws its own
background and border to look transparent on top of the previous
`MAAttachedWindow`'s near-black surface. Now that the popovers are
`NSPopover`s with system materials, the transparent look reads as a
plain unbordered button on a system blur, which is visually worse
than a normal push button. The custom button also has no dark-mode
awareness (it hard-codes light tints) and doesn't follow the system
control tint or accent color.

## Replacement

Plain `NSButton`s with `NSBezelStylePushButton`. AppKit handles:

- system materials inside the popover,
- light/dark appearance,
- accent color for the default ("Yes") button,
- key-equivalent rendering and focus ring.

`shareConfirm` gets `keyEquivalent = @"\r"` so it's the default
button (system tint), and `shareCancel` gets `@"\e"` (Escape).

## Approach

1. Replace the three `[[ETTransparentButton alloc] initWithFrame:]`
   allocations with `[[NSButton alloc] initWithFrame:]`.
2. Set `bezelStyle = NSBezelStylePushButton` and let AppKit auto-size
   from the title; keep an explicit width so the existing layout
   isn't shoved around.
3. Wire `keyEquivalent` for *Yes* and *No, thanks* so Enter / Escape
   behave correctly.
4. Drop the `#import "ETTransparentButton.h"` and
   `#import "ETTransparentButtonCell.h"` from
   `PreviewController.m`/`PreviewController.h`.
5. Delete `ETTransparentButton.{h,m}` and
   `ETTransparentButtonCell.{h,m}` from the repo and their entries
   from `project.pbxproj`.

## Files affected

- new: `docs/superpowers/specs/...-03-transparentbutton-spec.md`,
  `docs/native-controls/03-transparentbutton.md`.
- modified:
  - `PreviewController.h` — drop the
    `@class ETTransparentButton;` forward decl and change the three
    ivar types from `ETTransparentButton *` to `NSButton *`.
  - `PreviewController.m` — drop the two custom imports, switch the
    allocations, add key equivalents on the confirm/cancel pair.
  - `Notation.xcodeproj/project.pbxproj` — strip the four entries
    for `ETTransparentButton.{h,m}` and
    `ETTransparentButtonCell.{h,m}`.
- deleted: `ETTransparentButton.h`, `ETTransparentButton.m`,
  `ETTransparentButtonCell.h`, `ETTransparentButtonCell.m`.

## Risks

- The frame sizes (`81×28`, `116×28`) were tuned for the custom
  button cell's drawing. NSButton with `pushButton` style is closer
  to AppKit's standard 32-pt height; the existing height (28) is
  still acceptable and AppKit clamps internal padding. If buttons
  look cramped we'll adjust in a follow-up; structurally the
  approach holds.

## Verification

- arm64 build succeeds.
- Opening preview → share shows confirm popover with two standard
  push buttons; Enter activates *Yes*, Escape cancels. Both display
  correctly under light and dark appearance.
- After confirming, the second popover shows *View in Browser* as a
  standard push button; click opens the URL and dismisses the
  popover.
