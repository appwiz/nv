# Native Controls 13 — TitlebarButton → NSTitlebarAccessoryViewController

Companion to `docs/superpowers/specs/2026-05-30-native-controls-13-titlebarbutton-spec.md`.

## What changed

The custom title-bar sync-status button is replaced by an
`NSTitlebarAccessoryViewController` (10.10+) hosting an
`NSPopUpButton` and an `NSProgressIndicator`.

`TitlebarButton` (custom `NSPopUpButton`) and `TitlebarButtonCell`
(custom `NSPopUpButtonCell` with hover image drawing and a manual
`NSTimer`-driven spinner rotation) are deleted.

## How

The new class `NVTitlebarSyncAccessory` is a `~100-line
NSTitlebarAccessoryViewController` subclass that owns:

- An `NSPopUpButton` (`pullsDown:YES`, `bordered:NO`) anchored to
  the trailing edge of the title bar via
  `layoutAttribute = NSLayoutAttributeRight`.
- An `NSProgressIndicator` (small spinning style, indeterminate)
  shown only during sync.

State map matches the prior enum:

| `NVTitlebarSyncIconType` | UI |
| --- | --- |
| `…None` | accessory hidden |
| `…Chevron` | popup visible with `chevron.down.circle` SF Symbol |
| `…Synchronizing` | spinner visible + animating; popup hidden |
| `…Alert` | popup visible with `exclamationmark.triangle.fill` SF Symbol |

SF Symbols (10.16+) are used directly; `NSImage.template = YES`
makes them tint to the menu bar / accent color per appearance. A
pre-11 fallback path uses `NSImageNameCaution` for the alert state
and an empty image for the chevron — only matters if you somehow
run this build on 10.14/10.15.

The pull-down attached menu is wrapped: `NSPopUpButton` in
pull-down mode shows item 0 as the icon, so the caller's menu items
get prefixed with an empty placeholder item internally.

## Files

- **new**
  - `NVTitlebarSyncAccessory.h`, `NVTitlebarSyncAccessory.m`.
  - `docs/native-controls/13-titlebarbutton.md`,
    `docs/superpowers/specs/2026-05-30-native-controls-13-titlebarbutton-spec.md`.
- **modified**
  - `AppController.h`
    - replaced `@class TitlebarButton` with
      `@class NVTitlebarSyncAccessory`.
    - replaced the `TitlebarButton *titleBarButton` ivar with
      `NVTitlebarSyncAccessory *titleBarAccessory`.
  - `AppController.m`
    - swapped `#import "TitlebarButton.h"` for
      `#import "NVTitlebarSyncAccessory.h"`.
    - replaced the `[TitlebarButton alloc] initWithFrame:pullsDown:` /
      `addToWindow:` pair with `[NVTitlebarSyncAccessory alloc] init` /
      `[window addTitlebarAccessoryViewController:]`.
    - updated `dealloc` release.
    - replaced the four `setStatusIconType:` callers with
      `setIconType:NVTitlebarSyncIcon{Alert,Synchronizing,Chevron,None}`.
    - replaced `[titleBarButton setMenu:]` with
      `[titleBarAccessory setNv_menu:]` (named with the nv_ prefix
      to avoid colliding with NSResponder's own `menu` property).
  - `Notation.xcodeproj/project.pbxproj` — added the accessory
    class entries, removed the four `TitlebarButton` entries.
- **deleted**
  - `TitlebarButton.h`, `TitlebarButton.m`.

## Verification

- arm64 build succeeds.
- App launches without crash.
- Default state hides the title-bar accessory (matches the previous
  `NoIcon` behaviour when `ShowSyncMenu` is unset).
- With `defaults write … ShowSyncMenu YES`, a chevron icon appears
  at the right edge of the title bar; clicking shows the sync status
  menu.
- A live Simplenote sync swaps the chevron for the spinning
  indicator; the spinner stops when sync finishes.

## Known leftovers

The legacy bundled images (`TBDownArrow*`, `TBSynchronizing*`,
`TBAlert*`, `TBMousedownBG`, `TBRolloverBG`) are still in the app
bundle Resources. They have no references in code or NIBs after this
change. They'll be removed in a separate asset-cleanup pass.

## Reverting

`git revert <hash>` restores the deleted `TitlebarButton.{h,m}`,
puts the original setup back in AppController, and removes the
accessory class.
