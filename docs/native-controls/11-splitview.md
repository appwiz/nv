# Native Controls 11 — RBSplitView → NSSplitView

Companion to `docs/superpowers/specs/2026-05-30-native-controls-11-splitview-spec.md`.

## What changed

The notes-list / editor split is now a system `NSSplitView`
(subclassed thinly as `NVSplitView` to host the double-click-to-
collapse hit-test). The vendored `RBSplitView` system is deleted
along with the `LinearDividerShader` integration that drew its
custom divider on top.

| Before | After |
| --- | --- |
| `RBSplitView` (vendored, 10.4-era) | `NSSplitView` with `NSSplitViewDividerStyleThin` |
| `RBSplitSubview` (two custom subviews owned by the split view) | Plain `NSView` panes (`notesPane`, `editorPane`) wrapping the existing scroll views |
| Custom-drawn divider via `LinearDividerShader -drawDividerInRect:` | System thin divider; appearance-aware |
| `RBSplitView` autosave (`@"centralSplitView"`) | `NSSplitView` autosave (same key; AppKit's persisted-position format differs, so the position resets once on first launch) |
| `RB`-shaped delegate (`splitView:wasResizedFrom:to:`, `splitView:shouldHandleEvent:`, `splitView:willDrawDividerInRect:`, `splitView:canCollapse:`, `splitView:willCollapse:`, …) | `<NSSplitViewDelegate>` (`splitView:canCollapseSubview:`, `splitView:constrainMin/MaxCoordinate:`, `splitViewWillResizeSubviews:`, `splitViewDidResizeSubviews:`) |
| `[subview dimension]` / `setDimension:` / `collapse` / `expand` / `isCollapsed` | static helpers (`NVNotesPaneDimension`, `NVSetNotesPaneDimension`, `NVCollapseNotesPane`, `NVExpandNotesPane`) and `[splitView isSubviewCollapsed:]` |

## How

### `NVSplitView`

Eighteen-line `NSSplitView` subclass. The only override is
`-mouseDown:`: if the user double-clicks within the divider hit
region, the call gets forwarded to the app delegate's
`-toggleCollapse:`. AppKit doesn't expose a divider double-click
hook, but a `-mouseDown:` filter on the split view does the job
without touching private API.

### View hierarchy

Both panes are `NSView` wrappers so the editor's status overlay
(`editorStatusView`) can sit on top of the editor scroll view
without disturbing the split view's arrangement.

```
NVSplitView
├── notesPane (NSView)
│     └── notesScrollView (ETScrollView → NotesTableView)
└── editorPane (NSView)
      ├── textScrollView (ETNoteScrollView → LinkingEditor)
      └── editorStatusView (EmptyView, added on top elsewhere)
```

### Holding priorities

`-setHoldingPriority:forSubviewAtIndex:` gives the notes pane a
priority of `NSLayoutPriorityDefaultLow + 1`, and the editor pane
gets the lower `NSLayoutPriorityDefaultLow`. AppKit absorbs window
resizes into the lower-priority pane, so the notes pane keeps the
user's chosen width / height.

### Constraints / collapse

- `-splitView:canCollapseSubview:` allows collapsing only the
  notes pane and only when a note is selected (preserves the prior
  "you can't hide your only navigation when you've got nothing to
  read" rule).
- `-splitView:constrainMinCoordinate:ofSubviewAt:` floors the
  notes-pane size at 80 pt.
- `-splitView:constrainMaxCoordinate:ofSubviewAt:` reserves at
  least 100 pt for the editor.

### Live resize

`-splitViewWillResizeSubviews:` notes the first visible row and
re-pins it post-resize (the "Mail.app-like" behaviour).
`-splitViewDidResizeSubviews:` toggles `dualFieldIsVisible` based on
collapse state, mirroring the prior `willCollapse:` / `willExpand:`
callbacks.

### Removed plumbing

- `LinearDividerShader` allocation in `init`, `dealloc`, and
  `updateColorScheme` are gone (the class is still used by
  `DualField` for the snapback indicator and stays in the
  project).
- The `kSplitViewExpandedDividerThickness` / `kSplitViewCollapsedDividerThickness`
  macros are removed; the thin system divider is one consistent
  thickness in both states.
- `setMustAdjust` calls in the (now-removed) `willCollapse:` /
  `willExpand:` callbacks: AppKit batches relayout via
  `adjustSubviews`, which we still call after layout flips.
- `[splitView restoreState:YES]` (RB-specific): NSSplitView restores
  from `autosaveName` during NIB instantiation automatically.

## Files

- **new**
  - `NVSplitView.h`, `NVSplitView.m`.
  - `docs/native-controls/11-splitview.md`,
    `docs/superpowers/specs/2026-05-30-native-controls-11-splitview-spec.md`.
- **modified**
  - `AppController.h`
    - dropped `@class RBSplitView; @class RBSplitSubview; @class LinearDividerShader;`.
    - replaced `RBSplitSubview *splitSubview, *notesSubview` and
      `RBSplitView *splitView` ivars with `NSView *editorPane`,
      `NSView *notesPane`, `NVSplitView *splitView`.
    - dropped `LinearDividerShader *dividerShader` ivar.
  - `AppController.m`
    - dropped `#import "RBSplitView/RBSplitView.h"` and
      `#import "LinearDividerShader.h"`.
    - dropped `kSplitView*DividerThickness` macros.
    - rewrote the split-view setup block in `awakeFromNib` (~40
      lines) to use `NSSplitView` API + holding priorities.
    - replaced ~25 call sites (`[notesPane dimension]`,
      `setDimension:`, `collapse`, `expand`, `isCollapsed`) with the
      new static helpers.
    - rewrote the `#pragma mark SplitView Delegate methods` block
      (~110 lines) as `<NSSplitViewDelegate>` (~35 lines).
    - removed the `dividerShader` allocation, release, and
      `updateColorsWithBackgroundColor:` invocation.
  - `Notation.xcodeproj/project.pbxproj` — added NVSplitView
    entries, removed the entire RBSplitView group (5 PBXFileReference,
    2 PBXBuildFile, 1 PBXGroup, 2 Sources).
- **deleted**
  - `RBSplitView/RBSplitView.h`, `RBSplitView/RBSplitView.m`,
    `RBSplitView/RBSplitSubview.h`, `RBSplitView/RBSplitSubview.m`,
    `RBSplitView/RBSplitViewPrivateDefines.h` (the entire
    `RBSplitView/` folder).

## Verification

- arm64 build succeeds.
- App launches; the divider is a 1-pt system line that adapts to
  dark mode.
- Drag the divider: notes pane resizes; editor absorbs the rest.
- Double-click the divider: notes pane collapses; double-click
  again to expand.
- `View → Horizontal Layout` flips between top/bottom and
  left/right.
- Window resize: editor pane absorbs the delta, notes pane keeps
  its width.

## Known one-time regression

Users with an existing `centralSplitView` autosave entry in
`NSUserDefaults` will see the divider at AppKit's default starting
position once on first launch (the RB and NSSplitView autosave
serialisation formats differ; AppKit silently ignores the old
value). The position then persists normally.

## Reverting

`git revert <hash>` restores the `RBSplitView/` folder, the prior
AppController.h ivars, the kSplitView macros, and the original
delegate method block.
