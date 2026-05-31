# Native Controls Migration 11 — RBSplitView → NSSplitView

Date: 2026-05-30
Status: spec
Component: the vendored `RBSplitView` system
(`RBSplitView`, `RBSplitSubview`, `RBSplitViewPrivateDefines.h`) and
the `LinearDividerShader` invocation that fed the custom divider.

## Problem

`AppController` uses Rainer Brockerhoff's third-party split view to
host the notes list + editor. The class is from the 10.4 era,
implements its own divider drawing, custom subview collapse / expand
animations, configurable divider images, and a non-AppKit delegate
shape. It was a real win in the pre-NSSplitView-overhaul era; today
it does work AppKit handles natively, while not following system
appearance and offering no benefit over `NSSplitView`.

The split view is built **entirely in code** (no XIB references), so
the migration is a code-only swap.

## Replacement

System `NSSplitView`:

- Adapts to light/dark appearance automatically.
- Built-in `NSSplitViewDividerStyleThin` matches the existing look
  (1-pt line, no dimples).
- Standard `NSSplitViewDelegate` covers the collapse / constrain /
  resize callbacks we need.
- `autosaveName` persists divider position to UserDefaults for free
  (the RB equivalent had the same feature; the saved key changes,
  but losing one persisted divider position on first launch after
  upgrade is acceptable).

## Approach

1. **Subclass `NSSplitView` as `NVSplitView`** with two pieces of
   behaviour the system doesn't expose directly:
   - `dividerThickness` override so we can keep the split view's
     "expanded" thickness toggle (the current code uses 8 pt
     normally and 5 pt when the notes list is collapsed). Optional —
     may end up just using the thin divider style.
   - `mouseDown:` interception so double-click on the divider
     toggles the notes-list collapse (the RB version did this via
     `splitView:shouldHandleEvent:`).
2. **Build the split view** in `awakeFromNib`. Two child `NSView`
   wrappers (`notesPane`, `editorPane`) host `notesScrollView` and
   `textScrollView` respectively (`NSSplitView`'s arranged subviews
   are full-pane views, not the scroll views directly — wrapping
   makes the editor-status overlay easier to position).
3. **Rewrite the delegate methods** on `AppController` to the
   `NSSplitViewDelegate` protocol:
   - `-splitView:canCollapseSubview:` — only `notesPane`, only when
     a note is selected (matches existing semantics).
   - `-splitView:constrainMinCoordinate:ofSubviewAt:` and
     `-splitView:constrainMaxCoordinate:ofSubviewAt:` — replace the
     `setMinDimension:andMaxDimension:` calls on the RB subviews.
   - `-splitViewDidResizeSubviews:` — old `splitView:wasResizedFrom:to:`
     side effect of `adjustSubviewsExcepting:notesSubview` becomes
     a fixed-`notesPane` autosizing mask via
     `-holdingPriorityForSubviewAtIndex:` (notes pane gets a higher
     holding priority so the editor absorbs window resizes).
4. **Rewire the rest of AppController** to NSSplitView API:
   - `[splitView isVertical]` — semantically identical, no change.
   - `[notesSubview setDimension:x]` → `[splitView setPosition:x ofDividerAtIndex:0]`.
   - `[notesSubview dimension]` → derived from `notesPane.frame.size`.
   - `[notesSubview isCollapsed]` → `[splitView isSubviewCollapsed:notesPane]`.
   - `[notesSubview collapse]` / `expand` → `setPosition:0` /
     `setPosition:savedDimension`.
   - `[splitView adjustSubviews]` — same selector exists on
     NSSplitView.
   - `restoreState:` is implicit when autosaveName is set; the
     post-restore clamping logic stays as-is, just reading the
     restored frame from `notesPane`.
5. **Drop the divider shader path.** The
   `dividerShader updateColorsWithBackgroundColor:andForegroundColor:`
   call in `updateColorScheme` and the
   `splitView:willDrawDividerInRect:` delegate go away. The thin
   system divider already looks correct in both appearances. The
   `LinearDividerShader` class stays (it's still used by `DualField`
   for the snapback indicator).
6. **Delete the RBSplitView folder** (`RBSplitView.{h,m}`,
   `RBSplitSubview.{h,m}`, `RBSplitViewPrivateDefines.h`) and strip
   its pbxproj entries.

## Files affected

- new:
  - `NVSplitView.h`, `NVSplitView.m`.
  - `docs/superpowers/specs/...-11-splitview-spec.md`,
    `docs/native-controls/11-splitview.md`.
- modified:
  - `AppController.h` — drop the `RBSplitView`, `RBSplitSubview`
    forward decls; rename the `splitSubview` / `notesSubview` ivars
    to `editorPane` / `notesPane` and retype them as `NSView *`;
    retype `splitView` to `NVSplitView *`.
  - `AppController.m` — all the touchpoints listed in §4 / §5
    above.
  - `Notation.xcodeproj/project.pbxproj` — add NVSplitView entries,
    remove the RBSplitView group entries.
- deleted:
  - `RBSplitView/RBSplitView.h`, `RBSplitView/RBSplitView.m`,
    `RBSplitView/RBSplitSubview.h`, `RBSplitView/RBSplitSubview.m`,
    `RBSplitView/RBSplitViewPrivateDefines.h`.

## Risks / open questions

- **Persisted divider position.** Users who have an existing
  `centralSplitView` autosave entry in `NSUserDefaults` will lose
  their saved position on first launch after upgrade. The clamping
  logic in `applicationDidFinishLaunching` still picks a sensible
  default. Acceptable.
- **Double-click-to-collapse on divider.** RB's
  `shouldHandleEvent:` returned `NO` on double-click and we then
  toggled collapse manually. With NSSplitView we override
  `-mouseDown:` on `NVSplitView` to detect the double-click in the
  divider hit region and call the same `toggleCollapse:`. Same UX.
- **The `setMustAdjust` calls in fullscreen-collapse handlers.**
  RB used this to defer subview adjustment. NSSplitView batches via
  `adjustSubviews`; we replace with that.
- **Subview min/max constraints.** RB's `setMinDimension:1
  andMaxDimension:0` for the editor pane (1 pt min, no max) maps
  to a min-coordinate of 1 in the constrain delegate; the max
  coordinate is the split view's full dimension minus the notes
  pane's min, which AppKit calculates automatically when we don't
  return an opinion.

## Verification

- arm64 build succeeds.
- App launches; the divider is system-thin and adapts to dark mode.
- Drag the divider — notes pane resizes; editor absorbs the rest.
- Double-click the divider — notes pane collapses; double-click
  again — expands.
- `View → Horizontal Layout` toggle still flips between top/bottom
  and left/right arrangements.
- Restart the app — divider position persists.
- Window resize — editor pane absorbs the change; notes pane stays
  at user-set width.
