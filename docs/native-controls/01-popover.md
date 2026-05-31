# Native Controls 01 — MAAttachedWindow → NSPopover

Companion to `docs/superpowers/specs/2026-05-30-native-controls-01-popover-spec.md`.

## What changed

The two attached-popup overlays in the Markdown Preview window's
share UX are now `NSPopover`s instead of a hand-drawn `NSWindow`
subclass.

- "Share note?" confirm panel → `confirmPopover` (`NSPopover`).
- "Copied <url> to clipboard" notification → `urlPopover`
  (`NSPopover`).

Both are anchored under the share button via
`-showRelativeToRect:ofView:preferredEdge:NSRectEdgeMinY`. They use
`NSPopoverBehaviorTransient`, so click-outside or Escape dismisses
them. The system handles styling (rounded background, pointing
arrow, blur, light/dark appearance) — no app-side colors or radii to
maintain.

## How

The previous code allocated `MAAttachedWindow`, hand-set
`borderColor`, `backgroundColor`, `viewMargin`, `borderWidth`,
`cornerRadius`, arrow geometry, and then manually wired it as a
child window of `[shareButton window]`. Closing required
`removeChildWindow:` + `orderOut:` + `release` in every dismissal
path (`hide`, `cancel`, `openShareURL:`, `togglePreview:`,
`closeShareURLView`).

The new code introduces a small helper:

```objc
- (NSPopover *)makePopoverForView:(NSView *)contentView
                            owner:(NSViewController **)outVC;
- (void)showPopover:(NSPopover *)popover;
```

Each existing `NSView` IBOutlet (`shareConfirmation`,
`shareNotification`) is reused as the content view — no XIB changes —
by wrapping it in a freshly-allocated `NSViewController` whose `view`
is set directly. The popover's `contentSize` is taken from the
view's existing frame so the XIB-baked sizes apply.

Dismissal collapses to a single `[popover close]` everywhere. A new
`-popoverDidClose:` delegate method nils out the matching ivar and
its VC, so we don't have to remember to clean up state at every call
site.

## Files

- **`PreviewController.h`**
  - dropped `#import "MAAttachedWindow.h"`.
  - dropped the `MAAttachedWindow *attachedWindow` and
    `MAAttachedWindow *confirmWindow` ivars.
  - added `NSPopover *urlPopover`, `NSPopover *confirmPopover`,
    `NSViewController *urlPopoverVC`,
    `NSViewController *confirmPopoverVC` ivars.
  - adopted `<NSPopoverDelegate>` on `PreviewController`.

- **`PreviewController.m`**
  - added `-makePopoverForView:owner:` and `-showPopover:` helpers.
  - rewrote `-shareAsk:`, `-showShareURL:isError:`, `-cancelShare:`,
    `-hideShareURL:`, `-closeShareURLView`, `-openShareURL:` to use
    `NSPopover`.
  - rewrote the cleanup branch in `-togglePreview:` to close
    whichever popover may be open instead of poking child-window
    APIs.
  - added `-popoverDidClose:` for ivar cleanup on transient
    dismissal.

- **`MAAttachedWindow.h`**, **`MAAttachedWindow.m`** — deleted.

- **`Notation.xcodeproj/project.pbxproj`** — removed the three
  `MAAttachedWindow` entries (one PBXBuildFile, two PBXFileReference,
  and the two group / one Sources references).

## Verification

- `xcodebuild -arch arm64` succeeds with no new errors.
- The app launches and the preview window is reachable.
- Manual smoke check (please do this after pulling): open a note,
  open Preview, click *Share* — a popover should appear under the
  button with confirm/cancel; clicking outside dismisses it. After
  confirming, a second popover should appear with the copied URL and
  a *View on Web* button.

## Reverting

The change is contained in two files plus one xcodeproj edit. To
revert:

```
git revert <this commit's hash>
```

The reverted state restores `MAAttachedWindow.h/.m`, the prior
PreviewController code, and the pbxproj entries.
