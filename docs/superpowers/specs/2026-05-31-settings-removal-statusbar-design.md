# Settings removal + bottom status bar — design spec

Replace the entire Settings (Preferences) window with a thin status bar
at the bottom of the main window. The status bar exposes the two
settings the user cares about (body font, encryption) plus two
read-only indicators (lock state, note count). Every other current
preference is hardcoded to a chosen default. Power users keep an
escape hatch via `defaults write`.

Supersedes the work in commit-19 (`6df390a` — Settings layout
redesign). That redesign stays in history; this spec removes the
window it touched.

---

## Status bar layout

Width = main window content width. Height = ~28pt. Pinned to the
bottom of the main window with `flexibleMaxY` autoresizing so the
notes table / editor split above it absorbs vertical resize.

```
┌─────────────────────────────────────────────────────────────────────┐
│                                                                     │
│                                                                     │
│              (existing notes table / editor split)                  │
│                                                                     │
│                                                                     │
├─────────────────────────────────────────────────────────────────────┤
│ 🔒 347 notes                           [ ⚙ ] [ Aa  Helvetica 12 ▾ ]  │
└─────────────────────────────────────────────────────────────────────┘
   └── body font picker          └── indicators              └── encryption gear
       (changeable)                  (read-only)                 (changeable)
```

### Body font picker (left)

- A small `NSButton` with bezel style `NSBezelStyleRecessed` (or
  `NSBezelStyleInline` on 11+) showing the current font's display
  name and integer point size, e.g. `Aa  Helvetica 12`.
- Click opens the standard `NSFontPanel` for the body font (same code
  path as today's `Set…` button in the Fonts & Colors pane).
- Live-updates when the font changes (KVO on
  `GlobalPrefs.noteBodyFont` already exists; we just hook the
  button's title to it).

### Lock indicator (center-left, read-only)

- SF Symbol `lock.fill` (encrypted) or `lock.open` (not encrypted), in
  `labelColor`.
- Tooltip: "Notes are encrypted" / "Notes are not encrypted".
- No click action — it's purely an indicator. (The gear handles
  encryption changes.)

### Note count (center, read-only)

- `NSTextField`, system font 11pt, `secondaryLabelColor`.
- Format: `347 notes` (singular `1 note` for n=1, `0 notes` allowed).
- Updates via the existing `NotationController` note-count
  notification path (same numbers as the current title-bar count, if
  any).

### Encryption gear (right, changeable)

- `NSButton` with image `gearshape` (SF Symbol), bezel
  `NSBezelStyleInline`.
- Click opens a small `NSMenu` (popup attached to the button) with:
  - **Turn On Note Encryption…** / **Turn Off Note Encryption…**
    (toggle label based on current state — reuses the existing
    `NotationPrefs` encryption-toggle code path).
  - **Change Passphrase…** (disabled if encryption is off).
  - **Forget Passphrase from Keychain** (disabled if encryption is
    off or never stored).
- The existing modal sheets that handle these flows
  (`PassphrasePicker`, `PassphraseChanger`) are reused verbatim.

---

## Hardcoded defaults — what's no longer user-facing

The setter methods for these stay on `GlobalPrefs` /
`NotationPrefs` so existing user defaults migrate automatically (the
read paths are unchanged). Only the UI that called the setters goes
away. New installs land on the values below.

| Setting | Hardcoded default | Why |
|---|---|---|
| Use large font for List Text | OFF (10pt) | Matches the modern default we just shipped in commit-19. |
| Auto-select notes by title when searching | ON | Hits Enter does the right thing. |
| Confirm note deletion | ON | Data-loss guard. |
| Quit when closing window | OFF | macOS-native behavior. |
| Show menu bar icon | OFF | One persistent surface (status bar) is enough. |
| Hide Dock Icon | OFF | App is a regular dock app. |
| Storage format | Preserved per user; new installs = **Single Database (Allow Encryption)** | Encryption requires this format; we keep encryption changeable. |
| Notes folder | Preserved per user; new installs = `~/Documents/Notational Data` | Existing data must not move. |
| Confirm note files removed in Finder | ON | Data-loss guard. |
| Recognized file extensions | `.txt .md .markdown` | Today's set, unchanged. |
| Recognized file types (UTIs) | `net.daringfireball.markdown public.plain-text` | Today's set, unchanged. |
| Secure Text Entry | OFF | Edge case; flip via `defaults write` if needed. |
| Copy basic styles from other apps | OFF | Markdown editor — plain text wins. |
| Check spelling as you type | ON | Standard. |
| Tab key | Indent lines | Markdown editor expectation. |
| Soft tabs (spaces) | OFF | Tabs by default; Markdown is fine either way. |
| Make URLs clickable | ON | Shipped in commit-17. |
| Suggest titles for note-links | ON | Helpful. |
| Convert imported URLs to Markdown | OFF | Niche. |
| Auto-pair brackets | ON | Some users hate it; off is the safer default. |
| External Editor | unset | Cmd-click goes to the system default app. |
| Search Highlight: enabled | ON | Visible default. |
| Search Highlight: color | system yellow | Matches macOS find-bar yellow. |
| Always Show Grid Lines in Notes List | ON | Already today's default. |
| Alternating Row Colors | OFF | Modern macOS look. |
| Keep Note Body Width Readable | ON | Readability. |
| Max. Note Body Width | 800 px | Today's default. |

**Escape hatch.** Because the `GlobalPrefs` and `NotationPrefs` read
paths still consult `NSUserDefaults`, any of the above can be flipped
by a power user without us shipping UI:

```
defaults write com.brettterpstra.nvalt2 ConfirmNoteDeletion -bool NO
defaults write com.brettterpstra.nvalt2 AutoPairCharacters  -bool YES
```

(Exact key names follow whatever `GlobalPrefs` already writes — no
renames.)

---

## Files

### Deleted

- `PrefsWindowController.h`
- `PrefsWindowController.m`
- `NotationPrefsViewController.h`
- `NotationPrefsViewController.m`
- `en.lproj/Preferences.xib`
- `en.lproj/NotationPrefsView.nib/` (whole bundle)
- `NotationPrefsView.xib` (the XIB source from commit-19)

### Added

- `StatusBarView.h` / `StatusBarView.m` — the bottom strip, owns the
  four subviews, exposes the font-picker / encryption-gear actions.
  Lightweight `NSView` subclass; no nib.
- `docs/native-controls/20-settings-removal-statusbar.md` — change
  record for the commit (written *after* implementation).

### Modified

- `en.lproj/MainMenu.xib` — main window content view gets the
  status bar pinned at the bottom; the existing notes/editor split
  shrinks by the status bar's height. The Preferences menu item
  (Cmd+,) is removed from the app menu.
- `AppController.m` — wires the status-bar outlets, KVO on body font
  and encryption state, drives the gear menu's actions. Drops any
  references to `PrefsWindowController`.
- `GlobalPrefs.m` — fallback defaults (the dictionary handed to
  `NSUserDefaults registerDefaults:` at startup, or the per-getter
  `if not set, return X` fallbacks — whichever the file actually
  uses) updated to match the "Hardcoded default" column above.
  Setter methods stay; we only delete the ones whose *only* callers
  were the deleted UI (audit during implementation, not now).
- `NotationPrefs.m` — same treatment: fallback defaults updated; UI-
  only setters removed.
- First-launch directory flow — today nvALT prompts on first launch
  to pick the notes folder. The prompt stays for now (deleting it is
  out of scope and would be its own decision); we only ensure that
  the prompt's default suggestion is `~/Documents/Notational Data`.
- `Notational Velocity.xcodeproj/project.pbxproj` — remove the
  deleted files from the build, add the two new ones.

### Untouched

- Encryption flow XIBs: `PassphrasePicker.nib`, `PassphraseChanger.nib`,
  `KeyDerivationManager.nib` — these stay; the gear menu invokes them.
- Font panel — system-supplied, no XIB.

---

## Behavior details

### Cmd+,

Removed from the app menu. No replacement keystroke. (If we wanted
Cmd+, → focus body-font picker we could, but it's not worth a
custom binding for a once-per-month action.)

### First launch after upgrade

- Existing users keep their notes folder, storage format, and every
  other setting they had — because we never delete their user
  defaults and the read paths still consult them.
- The Preferences window simply doesn't open on Cmd+, anymore (menu
  item is gone).
- If a user is currently on a non-encrypting storage format (e.g.
  Plain Text Files), the encryption gear menu's "Turn On Note
  Encryption…" item is disabled with a tooltip explaining that
  encryption requires the Single Database format, which is no longer
  user-switchable. **Open question** — see below.

### Note count source

Reuse whatever `NotationController` already emits for table-row
count. No new computation.

### Encryption gear menu state

- "Turn On Note Encryption…" enabled when storage format supports it
  *and* encryption is currently off.
- "Turn Off Note Encryption…" enabled when encryption is currently on.
- "Change Passphrase…" enabled when encryption is on.
- "Forget Passphrase from Keychain" enabled when encryption is on
  *and* the passphrase is currently stored in the keychain.

---

## Out of scope

- Migrating Plain Text Files users to Single Database.
- Any change to the editor, table view, search field, or main toolbar.
- Localizing new strings into non-`en` `.lproj`s (the project only
  ships English today).
- Touching the encryption flow's internals — we reuse the existing
  sheets unchanged.

---

## Open questions

1. **Plain Text Files users + encryption gear.** Most existing
   nvALT users are on Plain Text Files (it's the popular mode). With
   storage format no longer user-switchable, the gear's "Turn On
   Encryption…" would be permanently disabled for them. Three options:
   (a) accept it — encryption was always a power-user feature anyway;
   (b) offer a one-time migration prompt "Switch to Single Database
   to enable encryption" when the disabled menu item is chosen;
   (c) re-add storage-format switching as a fifth status-bar slot
   (probably not — defeats the purpose).
2. **Note count placement.** Mock shows it center-of-bar. Would you
   prefer it at the far right next to the gear, or absent entirely? I updated the layout in the mock.
3. **Status bar visual style.** Mock implies a thin separator above
   it. Should it match the editor background, the table background,
   or use a translucent material (`NSVisualEffectView`,
   `.titlebar` material)? Match the table background.
4. **Body font picker label format.** Mock shows `Aa  Helvetica 12`.
   Drop the `Aa` glyph, show just `Helvetica 12`? Drop the glyph.
