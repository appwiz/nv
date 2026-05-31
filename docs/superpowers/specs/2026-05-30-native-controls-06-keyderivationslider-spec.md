# Native Controls Migration 06 — KeyDerivationDelaySlider → NSSlider

Date: 2026-05-30
Status: spec
Component: `KeyDerivationDelaySlider` + `KeyDerivationDelaySliderCell`
— a paired `NSSlider`/`NSSliderCell` subclass used in the database
encryption preferences sheet to choose the PBKDF2 key-derivation
delay.

## Problem

The slider class earns its keep two ways:

1. **Logarithmic value mapping.** The track is linear in `log(time)`
   so the user can easily pick values spanning two orders of
   magnitude (0.05 s … 4 s). The `-doubleValue`, `-setDoubleValue:`,
   `-minValue`, `-setMinValue:` and friends are all
   override-and-exponentiate.
2. **Mouse-up-only side effect.** The slider has
   `continuous = YES` so the user sees the time label update while
   dragging, but the expensive PBKDF2 iteration estimation should
   only run once when the user lets go. The custom cell hooks
   `-stopTracking:at:inView:mouseIsUp:` and forwards a `-mouseUp`
   message to the slider; the slider re-broadcasts that to a
   delegate (`KeyDerivationManager`).

Both responsibilities are application semantics, not "what a slider
is", so they belong in the controller. AppKit gives us a clean way
to detect mouse-up inside a continuous-slider's action: the action
fires once per mouse drag *and* once on mouse-up; the current event
type (`[[sender window] currentEvent].type`) is
`NSEventTypeLeftMouseUp` only on the latter.

## Replacement

A plain `NSSlider` with no custom cell. `KeyDerivationManager` owns:

- the linear→log mapping (stored value is in log space; convert to
  real time via `exp()` when reading, take `log()` when writing).
- the mouse-up branch inside its `IBAction sliderChanged:`.

## Approach

1. Add a helper category on the manager (or two private methods):
   `sliderRealValue` and `setSliderRealValue:`, which exp/log around
   `[slider doubleValue]` / `[slider setDoubleValue:]`.
2. Move the slider range setup
   (`numberOfTickMarks`, `minValue`, `maxValue`, `tickMarkPosition`,
   `allowsTickMarkValuesOnly`, `continuous`) out of the cell's
   `-init` and into `KeyDerivationManager`'s view-load path. The
   range values are stored in log space (`log(0.05)`, `log(4.0)`).
3. Rewrite `-sliderChanged:` in `KeyDerivationManager.m`:
   - read the real value via the new helper,
   - update the `hashDurationField` label every call (continuous),
   - check `[[sender window] currentEvent].type ==
     NSEventTypeLeftMouseUp`; if so, run the PBKDF2 estimation +
     setDoubleValue: correction + updateToolTip path that used to
     live in `mouseUpForKeyDerivationDelaySlider:`.
4. Delete `-mouseUpForKeyDerivationDelaySlider:` from
   `KeyDerivationManager.h/.m`.
5. Delete `KeyDerivationDelaySlider.h`, `KeyDerivationDelaySlider.m`.
6. Update any nib references: replace `KeyDerivationDelaySlider`
   custom class with `NSSlider` in
   `*.lproj/KeyDerivationManager.{xib,nib}`.
7. Strip the pbxproj entries for the deleted files.

## Files affected

- new: `docs/superpowers/specs/...-06-keyderivationslider-spec.md`,
  `docs/native-controls/06-keyderivationslider.md`.
- modified: `KeyDerivationManager.h`, `KeyDerivationManager.m`,
  every `KeyDerivationManager.{xib,nib}` per locale,
  `Notation.xcodeproj/project.pbxproj`.
- deleted: `KeyDerivationDelaySlider.h`,
  `KeyDerivationDelaySlider.m`.

## Risks / open questions

- The XIBs that reference `KeyDerivationDelaySlider` may be binary
  nibs in some locales. We'll grep first and patch text NIBs; if any
  binary nib references the class, we'll re-point it via Interface
  Builder later or live with a runtime fallback (Cocoa loads a class
  it can't find as `NSObject`, which would break — so binary nibs
  need attention).
- The "currentEvent on the slider's window" trick relies on
  AppKit's standard control event dispatch and is documented; it's
  used widely.

## Verification

- arm64 build succeeds.
- Open Preferences → Database → set encryption → drag the
  "Key derivation delay" slider. The time label updates live; the
  estimated iteration count only refreshes on mouse-up. The slider
  snaps to the corrected position after the mouse-up estimation.
