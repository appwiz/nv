# Native Controls Migration 01 — MAAttachedWindow → NSPopover

Date: 2026-05-30
Status: spec
Component: `MAAttachedWindow` (third-party borderless-window popup) in
`PreviewController`.

## Problem

`PreviewController` uses `MAAttachedWindow` for two transient
attached-to-button overlays:

- `confirmWindow` — "Share note?" confirm/cancel buttons.
- `attachedWindow` — "Copied <url> to clipboard" notification with a
  *View on Web* button.

`MAAttachedWindow` is a custom `NSWindow` subclass from 2008 that
draws its own rounded background, border, and pointing arrow. It is
explicitly themed with `setBackgroundColor:` /
`setBorderColor:` and ignores system appearance — under dark mode it
looks identical to under light mode (because both call sites hard-code
near-black colors). The plumbing also requires manual
`[parentWindow addChildWindow:ordered:]` /
`[parentWindow removeChildWindow:]` + `orderOut:` + `release` dance,
which is easy to get wrong.

## Replacement

`NSPopover` (AppKit, 10.7+). NSPopover:

- Renders with system materials (`NSPopoverAppearanceMinimal` /
  `NSPopoverBehaviorTransient`); follows light/dark automatically.
- Anchored via `showRelativeToRect:ofView:preferredEdge:`.
- Owns its window. Closes itself on click-outside when
  `behavior = NSPopoverBehaviorTransient`.
- Has a clean delegate (`NSPopoverDelegate`) for did-close.

## Approach

1. Replace the two `MAAttachedWindow *` ivars on `PreviewController`
   with two `NSPopover *` ivars (`confirmPopover`, `urlPopover`) plus
   two `NSViewController *` wrappers (`confirmPopoverVC`,
   `urlPopoverVC`).
2. Reuse the existing `shareConfirmation` and `shareNotification`
   IBOutlet `NSView`s as the popover content views by handing each to
   a freshly-allocated `NSViewController` (set `view` on the VC).
   No XIB changes needed.
3. Adopt `<NSPopoverDelegate>` on PreviewController. Use
   `popoverDidClose:` to clear the corresponding ivar.
4. Show via
   `showRelativeToRect:[shareButton bounds] ofView:shareButton preferredEdge:NSRectEdgeMinY`.
5. Close via `[popover close]`.
6. Drop the hand-rolled border/background/arrow configuration — those
   knobs don't exist on NSPopover and aren't needed.
7. Delete `MAAttachedWindow.h` and `MAAttachedWindow.m` from the
   project and the build phases.

## Files changed

- `PreviewController.h`
  - drop `#import "MAAttachedWindow.h"`;
  - drop `MAAttachedWindow *attachedWindow`,
    `MAAttachedWindow *confirmWindow` ivars;
  - add `NSPopover *urlPopover`, `NSPopover *confirmPopover` ivars
    plus matching VC wrappers;
  - declare conformance to `NSPopoverDelegate`.
- `PreviewController.m`
  - rewrite `-shareAsk:`, `-showShareURL:isError:`, `-cancelShare:`,
    `-hideShareURL:`, `-closeShareURLView`, `-openShareURL:`, and the
    cleanup path in `-togglePreview:`;
  - add `-popoverDidClose:` to nil out ivars when the user dismisses
    by click-outside or escape.
- `Notation.xcodeproj/project.pbxproj`
  - remove the `MAAttachedWindow.h/.m` PBXBuildFile, PBXFileReference,
    group, and Sources entries.
- `MAAttachedWindow.h`, `MAAttachedWindow.m` — deleted from the repo.

## Risks / open questions

- The `shareConfirmation` and `shareNotification` views in the XIB
  may have fixed frames that look slightly off inside an `NSPopover`.
  The popover will resize to the VC's view's bounds at show time, so
  the existing frames should be honoured; if the popover looks
  cramped or wrong we can adjust the view frames in a follow-up
  without changing the architecture.
- `MAAttachedWindow` is not imported anywhere else in the codebase
  (verified by grep), so removing it is safe.

## Verification

- arm64 build succeeds.
- App launches; opening the preview, hitting the share button shows a
  popover anchored under the button; "share" copies the URL and shows
  a second popover; *View on Web* opens the URL and closes the
  popover.
- Clicking outside the popover (or pressing Escape) dismisses it.
- Light/dark system appearance both produce correct popover
  rendering with no per-mode color overrides.
