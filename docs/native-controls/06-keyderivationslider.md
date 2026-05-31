# Native Controls 06 — KeyDerivationDelaySlider → NSSlider

Companion to `docs/superpowers/specs/2026-05-30-native-controls-06-keyderivationslider-spec.md`.

## What changed

The PBKDF2 key-derivation delay slider in the database encryption
preferences sheet is now a stock `NSSlider`. Both helper classes —
`KeyDerivationDelaySlider` (custom NSSlider subclass with log/exp
value mapping) and `KeyDerivationDelaySliderCell` (custom cell that
forwarded a mouse-up callback) — are deleted.

The log-space value mapping and the "fire the expensive estimation
only on mouse-up" behaviour both moved into `KeyDerivationManager`,
which is where that application logic belongs.

## How

### Log-space value mapping

The slider stores its position in log space; the manager translates
to and from real seconds via two new helpers:

```objc
- (double)sliderRealValue {
    return exp([slider doubleValue]);
}

- (void)setSliderRealValue:(double)realSeconds {
    [slider setDoubleValue:log(realSeconds)];
}
```

`-awakeFromNib` now sets `setMinValue:log(0.025)` /
`setMaxValue:log(3.5)` along with the existing tick / continuity
settings that used to live in the cell's `-init`.

### Mouse-up commit inside a continuous slider

A continuous `NSSlider` sends its action on every drag step *and*
once on mouse-up. We tell them apart by inspecting the current
event:

```objc
NSEvent *currentEvent = [[(NSControl *)sender window] currentEvent];
if ([currentEvent type] == NSEventTypeLeftMouseUp) {
    /* expensive estimation + snap-back */
}
```

So the time label updates live as the user drags, and the PBKDF2
estimation only runs once when they let go — exactly the prior
behaviour, without a custom cell.

### XIB compatibility shim

The six localized `KeyDerivationManager.nib` bundles still archive
the slider with `$classname = "KeyDerivationDelaySlider"`. Rather
than re-archive six binary nibs, we add one line in
`KeyDerivationManager +load`:

```objc
+ (void)load {
    [NSKeyedUnarchiver setClass:[NSSlider class]
                   forClassName:@"KeyDerivationDelaySlider"];
}
```

`NSKeyedUnarchiver` honours this default for every subsequent
unarchive — including AppKit's nib-loading machinery — so each nib
materialises a plain `NSSlider`. Future nib re-saves from Interface
Builder will drop the custom-class marker naturally.

## Files

- **modified**
  - `KeyDerivationManager.h`
    - dropped `@class KeyDerivationDelaySlider;`.
    - changed `IBOutlet KeyDerivationDelaySlider *slider` to
      `IBOutlet NSSlider *slider`.
    - dropped `-mouseUpForKeyDerivationDelaySlider:` declaration.
  - `KeyDerivationManager.m`
    - dropped `#import "KeyDerivationDelaySlider.h"`.
    - added `+load` that registers the class alias.
    - `-awakeFromNib` now configures the slider range/ticks
      directly.
    - `-sliderChanged:` does the live label update on every call and
      the PBKDF2 estimation / snap-back only on the mouse-up event.
    - added `-sliderRealValue` / `-setSliderRealValue:` helpers.
    - removed `-mouseUpForKeyDerivationDelaySlider:` entirely.
  - `Notation.xcodeproj/project.pbxproj`
    - removed the four entries for
      `KeyDerivationDelaySlider.{h,m}`.
- **deleted**
  - `KeyDerivationDelaySlider.h`, `KeyDerivationDelaySlider.m`.

## Verification

- arm64 build succeeds.
- Open *Preferences → Database → set up password* → drag the
  "Key derivation delay" slider:
  - the time label updates live while dragging,
  - on mouse-up the slider snaps to a slightly different position
    (the iteration estimator's corrected delay), and the tooltip
    updates with the iteration count,
  - the iteration estimator progress spinner appears for any
    correction longer than 0.7 s.

## Reverting

`git revert <hash>` restores both deleted files and the prior
manager code.
