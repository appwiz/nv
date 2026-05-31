# Native Controls 16 — Toolbar / search-bar visual polish

Follow-up to commits 12 (DualField deferred) and 13 (TitlebarButton).
Driven by interactive screenshots after launching the rebuilt app on
macOS 26.5.

## Problems observed

1. **Dark vertical bars on the right side of the search bar.** The
   `DFCapLeftRounded` / `DFCapRight` TIFF assets that `DualField
   -drawRect:` was painting at the ends of the field have no
   dark-mode variants; they showed up as bright slivers against the
   dark toolbar.
2. **5-pt dark gaps either side of the search bar.** The field's
   fill was `NSRectFill(NSInsetRect(tBounds, 5, 1))`, leaving the
   window background visible on the inset edges.
3. **Hard-rectangular dark fill inside a rounded toolbar pill.** On
   macOS 11+ the system wraps custom view toolbar items in a
   rounded "pill" bezel; our `NSRectFill` painted a flat rectangle
   over it.
4. **`nvALT` title eats the leading half of the toolbar.** Default
   `setTitleVisibility` is `NSWindowTitleVisible`, so the search
   field could only start partway across.
5. **"N⌄" instead of the chevron icon in the title bar.** The new
   `NVTitlebarSyncAccessory` used `NSPopUpButton` in pulls-down
   mode; pulls-down popups display item 0's title (which had ended
   up non-empty after the menu-wrap) next to the system pull-down
   arrow, so the user saw the start of a menu item followed by `⌄`.
6. **Clear ("x") icon invisible in dark mode.** `DualFieldCell`
   drew the bundled black `Clear.tif`; black against a dark surface
   is invisible.
7. **Same icon still invisible after switching it to SF Symbol
   `xmark.circle.fill` with `template = YES`.** `NSImage`'s
   template flag only auto-tints when the image is drawn via
   `NSButton` / `NSImageView` / similar host. Cell-style direct
   `drawInRect:` (which `drawCenteredInRect:` ultimately uses)
   ignores the flag.
8. **Search-field text too light to read in light mode after a dark
   start.** `DualField -setTextColor:` was set once at
   `awakeFromNib`. When `[NSApp effectiveAppearance]` flipped,
   `updateColorScheme` re-themed everything *except* the field's
   cached static text color.
9. **Field has no visible edge in any state.** Once the hand-drawn
   chrome was removed the field merged into the surrounding pill;
   the user asked for a light border visible in both appearances.

## Fixes

### 1–3 · DualField fill

`DualField -drawRect:` is reduced to a transparent paint. We don't
fill the bounds at all; the `NSToolbarItem`'s natural background
shows through. The cap-image draws (with their `DFCap*` TIFFs) and
the four hand-stroked edges are gone. The cell still paints the
document icon (Pencil / Search), the clear button, the snapback
chip, and the text.

### 4 · Window title hidden, toolbar item promoted

```objc
[window setTitleVisibility:NSWindowTitleHidden];
[dualFieldItem setVisibilityPriority:NSToolbarItemVisibilityPriorityHigh];
```

With the title hidden, the toolbar's leading edge starts at the
window's content edge (immediately after the traffic-light buttons),
and the high-priority dual-field item expands as far as the trailing
edge allows.

### 5 · NVTitlebarSyncAccessory uses NSButton, not NSPopUpButton

`NSPopUpButton` in pulls-down mode insists on displaying item 0's
title next to its system pull-down arrow. Even with an explicit
empty placeholder item, swapping the popup's menu (so the wrapped
menu's first item could be empty) wasn't reliable across menu
rebuilds. Replaced with an unbordered `NSButton` (`imagePosition =
NSImageOnly`, `title = @""`) whose action calls
`-popUpMenuPositioningItem:atLocation:inView:` on the attached menu.
The button shows just the SF Symbol; clicking pops the sync-status
menu under it.

### 6 · Clear icon → SF Symbol fallback

Replaced `[NSImage imageNamed:@"Clear"]` with
`[NSImage imageWithSystemSymbolName:@"xmark.circle.fill"
                accessibilityDescription:@"Clear"]` on macOS 11+,
falling back to the bundled TIFF on older systems.

### 7 · Manual tint, since template flag doesn't reach this draw path

A new static helper `NVClearButtonImage(pressed)` returns a fresh
`NSImage` with the desired tint *baked in* via the source-in
compositing recipe:

```objc
NSImage *tinted = [[NSImage alloc] initWithSize:sz];
[tinted lockFocus];
[symbol drawInRect:r];                                  // alpha mask
[(pressed ? labelColor : secondaryLabelColor) set];
NSRectFillUsingOperation(r, NSCompositingOperationSourceIn); // tint
[tinted unlockFocus];
```

`secondaryLabelColor` / `labelColor` are dynamic — they resolve to
the correct grey for the current appearance. Since a fresh image is
returned every draw, appearance flips just work.

### 8 · Re-apply text color on every appearance flip

Added two lines to `AppController -updateColorScheme`:

```objc
[field setTextColor:[NVAppearance fieldTextColor]];
[field setNeedsDisplay:YES];
```

`updateColorScheme` is already invoked from KVO on
`[NSApp effectiveAppearance]`, so dark → light → dark transitions
keep the field text legible.

### 9 · Rounded separator-tinted border

`DualField -drawRect:` now strokes a 1-pt rounded rect (4-pt
corner radius) using `NSColor.separatorColor`, the system's
appearance-aware separator grey. Visible in both modes, in both
focused and unfocused states.

## Files

- **modified**
  - `AppController.m`
    - `-setDualFieldInToolbar`: set
      `dualFieldItem.visibilityPriority = NSToolbarItemVisibilityPriorityHigh`,
      `dualFieldItem.bordered = NO` (opts out of the macOS 11+
      rounded pill bezel, so the field sits flush in the toolbar
      area), and `window.titleVisibility = NSWindowTitleHidden`.
    - `-updateColorScheme`: re-apply
      `[field setTextColor:[NVAppearance fieldTextColor]]` and
      mark for display.
  - `DualField.m`
    - `-drawRect:` shrunk: no `NSRectFill`, no cap-image draws, no
      hand-stroked edges; just the rounded border, the doc icon,
      and a `[[self cell] drawWithFrame:…]` call.
    - new static helper `NVClearButtonImage(BOOL pressed)` returns a
      tinted-in-place SF Symbol (or bundled TIFF fallback) so the
      clear icon is appearance-aware.
    - `DualFieldCell -drawWithFrame:inView:` calls the new helper
      instead of `imageNamed:@"Clear"` / `@"ClearPressed"`.
  - `NVTitlebarSyncAccessory.m`
    - swapped the `NSPopUpButton` for an unbordered `NSButton`
      with `-action: @selector(showMenu:)`; the action calls
      `popUpMenuPositioningItem:atLocation:inView:` on the
      attached menu.

## Verification

- arm64 build succeeds.
- App launches.
- In dark mode the search bar shows a thin rounded border with no
  hard rectangle inside; the clear icon is visible against the dark
  field.
- Flipping system appearance live (System Settings → Appearance)
  keeps the field text legible and the border visible without a
  relaunch.
- The title-bar sync accessory shows the `chevron.down.circle` SF
  Symbol when `ShowSyncMenu` is on; no `"N⌄"`.

## Reverting

`git revert <hash>` restores the prior `DualField -drawRect:` block,
the `NSPopUpButton`-based accessory, the bundled clear-icon code
path, and the original `setDualFieldInToolbar` body.
