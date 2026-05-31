# Native Controls 20 — Settings removed, replaced by bottom status bar

End-to-end removal of the Settings (Preferences) window. The two
settings users actually care about (body font, encryption) are now
exposed via a thin always-visible status bar at the bottom of the
main window; everything else is hardcoded to a chosen default.

Supersedes commit-19's layout redesign of the same window — that
window is now gone entirely. The spec for this rework is
`docs/superpowers/specs/2026-05-31-settings-removal-statusbar-design.md`.

Shipped as five sequential commits so each step is independently
revertable:

| Hash      | Commit | What it does |
|-----------|--------|--------------|
| `55f2ee5` | 20a    | Add `StatusBarView` + wire it into `AppController`. Preferences window still around. |
| `dc7fa50` | 20b    | Update `GlobalPrefs` / `NotationFileManager` defaults to match the spec. |
| `d155d80` | 20c    | Delete `PrefsWindowController`, `NotationPrefsViewController`, all `Preferences.xib` / `NotationPrefsView.nib` locales, and the Cmd+, menu item. |
| `d339df9` | 20d    | First wiring fix — drop the misaligned lock icon and switch `AppController` to inherit from `NSResponder`. |
| (this)    | 20e    | Final wiring fixes — gear menu pops on click, body-font picker actually applies + persists. |

## Status bar (commit-20a)

A new `StatusBarView` (`NSView` subclass, no nib) is installed at
the bottom of the main window's content view in
`AppController -setupViewsAfterAppAwakened`. It carries:

- **Body Font button** (right group, left half) — recessed,
  shows-border-on-hover. Title is `<displayName> <pointSize>`, e.g.
  `Helvetica 12`. Click opens `NSFontPanel`; changes route via
  `-changeFont:` on `StatusBarView` (which it becomes first
  responder of for the duration) and call back into
  `AppController -statusBarView:didReceiveFontChange:`, which applies
  the font through `GlobalPrefs setNoteBodyFont:sender:`. Bold /
  italic variants are rejected with a beep (preserves the prior
  behavior from `PrefsWindowController`).
- **Encryption gear button** (right group, rightmost) — wired to
  `-showGearMenu:` which calls `popUpMenuPositioningItem:atLocation:
  inView:` (a plain `setMenu:` doesn't make a non-popup-style button
  show its menu on click). Menu rebuilt on every show so item
  titles/enablement track current state. Items:
  - **Turn On / Off Note Encryption…** (single toggle). On Plain
    Text Files storage, the "On" form is disabled with a tooltip
    explaining the restriction.
  - **Change Passphrase…** (enabled only when encryption is on).
  - **Forget Passphrase from Keychain** (enabled only when
    encryption is on AND the passphrase is in the Keychain).
  - All three reuse the existing `PassphrasePicker` and
    `PassphraseChanger` sheets verbatim — those classes survive the
    deletion in commit-20c.
- **Lock icon** (left, leftmost) — SF Symbol `lock.fill` (encrypted)
  or `lock.open` (not), tinted `labelColor` / `secondaryLabelColor`,
  with a matching tooltip.
- **Note count** (left, just right of the lock) —
  `[notationController totalNoteCount]`, refreshed on every
  `-notationListDidChange:` callback and on `-setNotationController:`.
  Singular/plural correct.

The bar is 28pt tall, pinned at y=0 with
`NSViewWidthSizable | NSViewMaxYMargin`. On install, existing window
content subviews are shifted up by 28pt and shrunk so the editor
split occupies the remaining space.

The body-font picker plumbing went through three iterations across
commits 20a → 20d → 20e before it landed:

1. **20a** parked `StatusBarView` as first responder, made it
   implement `-changeFont:`, and forwarded to `AppController` via a
   `StatusBarViewFontDelegate` protocol. This didn't work because
   `NSFontPanel` briefly becomes key while interacted with, and the
   responder chain walks the panel's chain rather than the main
   window's.
2. **20d** changed `AppController` to inherit from `NSResponder`
   directly so the panel-key responder chain eventually reaches it
   via `NSApp.delegate`. The chain did fire, but the new font
   silently never applied.
3. **20e** finally found the real bug: the chain reached
   `AppController`, but the `setNoteBodyFont:sender:` call was
   passing `self` as sender, and `GlobalPrefs`'s callback fan-out
   in `-notifyCallbacksForSelector:excludingSender:` explicitly
   *excludes the sender*. So `AppController`'s own
   `-settingChangedForSelectorString:` handler (which runs
   `restyleAllNotes` + `refreshStatusBarBodyFont`) never fired.
   Pass `sender:nil`.

20e also added two more fixes the user surfaced:

- `NSTextView` (`LinkingEditor`) inherits `-changeFont:` and
  applies the font to selected text. While the editor was first
  responder, it consumed the message before the chain reached us.
  `pickBodyFont:` now calls `[window makeFirstResponder:window]`
  before showing the panel.
- `NotationPrefs` stores its own per-database `baseBodyFont`, and
  at startup `-resolveNoteBodyFontFromNotationPrefsFromSender:`
  compares it to the global default and resets the global back if
  they mismatch. Without keeping them in sync, the next launch
  reverts the user's choice. `changeFont:` now also calls
  `[notationPrefs setBaseBodyFont:newFont]` so they track.

## Hardcoded defaults (commit-20b)

`GlobalPrefs.m -registerDefaults:` changes:

| Key                          | Was        | Now           | Reason |
|------------------------------|------------|---------------|--------|
| `QuitWhenClosingMainWindowKey` | YES      | NO            | macOS-native: closing the window doesn't quit. |
| `PastePreservesStyleKey`      | YES       | NO            | Markdown editor; plain text wins on paste. |
| `UseAutoPairing`              | NO        | YES           | Per user-edited spec. |
| `KeepsMaxTextWidth`           | NO        | YES           | Readability. |
| `NoteBodyMaxWidth`            | 660.0     | 800.0         | Per spec. |
| `SearchTermHighlightColorKey` | custom pink | system yellow | Matches macOS find-bar yellow. |

`NotationFileManager.m getDefaultNotesDirectoryRef:` changes:

- First-launch fallback directory moves from
  `~/Library/Application Support/Notational Data` to
  `~/Documents/Notational Data`. More visible now that the
  notes-folder picker is gone from the prefs UI.

`NotationPrefs.m` already defaulted to `SingleDatabaseFormat`,
`confirmFileDeletion = YES`, `secureTextEntry = NO` — no edits
needed.

All read paths still consult `NSUserDefaults`, so existing user
defaults migrate automatically and power-users keep the
`defaults write com.brettterpstra.nvalt2 …` escape hatch.

## Deletions (commit-20c)

Files deleted:

- `PrefsWindowController.h` / `.m`
- `NotationPrefsViewController.h` / `.m`
- `NotationPrefsView.xib` (canonical source from commit-19)
- `en.lproj/Preferences.xib`
- `en.lproj/NotationPrefsView.nib/` (whole bundle)
- All non-English locales: `de.lproj`, `it.lproj`, `zh.lproj`,
  `pt-PT.lproj`, `fr.lproj` versions of `Preferences.xib` and
  `NotationPrefsView.nib`
- All Xcode project references for the above.

Edits:

- `en.lproj/MainMenu.xib` — both `Preferences…` menu items (in the
  app menu and the alternate menu) and their separators removed,
  along with the `showPreferencesWindow:` connections. Cmd+, is no
  longer bound.
- `AppController.h` / `.m` — drop the `prefsWindowController` ivar,
  the `PrefsWindowController` import / `@class`, and the
  `-showPreferencesWindow:` action. The first-launch directory
  picker (`-getNewNotesRefFromOpenPanel:returnedPath:`) is ported
  from `PrefsWindowController` into `AppController` so the existing
  fallback at `AppController.m:476` keeps working.
- `NotationPrefs.m` — `#import "NotationPrefsViewController.h"`
  removed; the three internal casts in
  `-noteFilesCleanupSheetDidEnd:returnCode:contextInfo:` switched
  from `(NotationPrefsViewController*)` to `(id)`. That method is
  now dead code (nothing constructs a sheet that would fire it) but
  still compiles; sweeping it out can wait for a future commit.

Stale references left intentionally:

- Two doc-comments in `ExternalEditorListController.m` still
  mention `PrefsWindowController`. They describe rationale, not
  active wiring, so they're harmless and clarify intent for the
  next reader.
- The `noteFilesCleanupSheetDidEnd:returnCode:contextInfo:` and
  `shouldDisplaySheetForProposedFormat:` pair on `NotationPrefs` —
  dead but compiles, see above.

## Verification

- arm64 build succeeds (`** BUILD SUCCEEDED **`).
- App launches; main window shows the bottom status bar with body
  font label, lock icon, note count, gear button.
- App menu no longer has a `Preferences…` item; Cmd+, does nothing.
- Existing notes folder + storage format honored; nothing migrated.

## Reverting

The three commits stack — `git revert <hash>` on the latest restores
the deletion; revert both `20b` and `20c` to restore the old
defaults; revert all three to restore the entire Preferences window.
