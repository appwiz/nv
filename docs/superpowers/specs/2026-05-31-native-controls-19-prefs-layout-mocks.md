# Native Controls 19 — Preferences window layout (ASCII mocks)

Edit this file in place. I'll pick up whatever's here and translate
the mocks + design-choice answers into XIB layout changes.

Conventions used in the mocks (so you know what to tweak):

- `[ ]` / `[x]` — checkbox (off / on)
- `( )` / `(•)` — radio button (off / on)
- `[ Value ▾ ]` — popup button
- `[ _____________ ]` — text field
- `{ Button }` — push button
- `[ ====●──── ]` — slider
- `[+]` / `[-]` / `[★]` — table edit buttons (add / remove / make-default)
- Outer `┌─ … ─┐` box represents the visible **content area** of the
  window (i.e. inside the toolbar / title bar). Width is ~76 chars.

If you want a different overall window width, say so at the bottom of
this file and I'll match column positions to it.

---

## Design choices

Edit any of these; the mocks below should be consistent with whatever
the choices say.

1. **Label column axis** — right-aligned labels ending at the same x
   on every pane. Controls start one space right of the colon.
   Currently chosen: ends around column 30 in the mocks. Edit to
   change.
2. **Checkbox column** (for boolean lists with no label): left margin
   at column 3. Used in General's middle block, Fonts & Colors'
   bottom block.
3. **Pane widths**: all four panes the same content width so the
   window doesn't jump when switching tabs. The toolbar minimum sets
   the floor; pick a number that fits all four cleanly.
4. **Indented helper text**: small-system-font helper text indented
   under the control it explains, not floating mid-row.
5. **Group separation**: blank line between groups inside a pane.
6. **Editing pane label column** ends at the same x as General and
   Fonts & Colors (one shared axis across all panes).

---

## General

```
┌────────────────────────────────────────────────────────────────────────┐
│                                                                        │
│   [ ] Use large font for List Text                                     │
│                                                                        │
│   [ ] Auto-select notes by title when searching                        │
│       Automatically selecting very long notes may affect               │
│       responsiveness.                                                  │
│                                                                        │
│   [ ] Confirm note deletion                                            │
│   [ ] Quit when closing window                                         │
│   [ ] Show menu bar icon                                               │
│                                                                        │
│  --------------------------------------------------------------------  │
│   { Hide Dock Icon }                                                   │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
```

## Notes — outer

```
┌────────────────────────────────────────────────────────────────────────┐
│                                                                        │
│      Read notes from folder:  [ 📁 Notational Data ▾ ]                 │
│                                                                        │
│   ┌─ Storage ─┬─ Security ─┐                                           │
│   │                                                                │   │
│   │   (active sub-tab content — see below)                         │   │
│   │                                                                │   │
│   └────────────────────────────────────────────────────────────────┘   │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
```

### Notes › Storage

```
┌────────────────────────────────────────────────────────────────────────┐
│                                                                        │
│  Store and read notes on disk as:  [ Single Database (Allow Enc.) ▾ ]  │
│                                                                        │
│  [ ] Confirm note files removed in the Finder                          │
│                                                                        │
│  Recognize individual files with attributes:                           │
│                                                                        │
│       ┌─ Extension ─────────────────────────┐                          │
│       │  .txt                               │                          │
│       │  .md                                │   [+]  [-]  [★]          │
│       │  .markdown                          │                          │
│       │                                     │                          │
│       └─────────────────────────────────────┘                          │
│                                                                        │
│       ┌─ File Type ─────────────────────────┐                          │
│       │  net.daringfireball.markdown        │                          │
│       │  public.plain-text                  │   [+]  [-]               │
│       │                                     │                          │
│       └─────────────────────────────────────┘                          │
│                                                                        │
│   * Using separate files allows Spotlight integration, but wastes      │
│     disk space.                                                        │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
```

### Notes › Security

```
┌────────────────────────────────────────────────────────────────────────┐
│                                                                        │
│            Encryption:  { Turn On Note Encryption… }                   │
│                                                                        │
│            Passphrase:  { Change… }                                    │
│                                                                        │
│           Bits in key:  [ 256 ]  ▴▾                                    │
│                                                                        │
│  ┌─ Password storage ─────────────────────────────────────────────┐    │
│  │  (•) Remember in Keychain        { Clear in Keychain }         │    │
│  │  ( ) Ask every time                                            │    │
│  └────────────────────────────────────────────────────────────────┘    │
│                                                                        │
│              Keyboard:  [ ] Secure Text Entry                          │
│                         Can impede keystroke logging utilities.        │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
```

## Editing

```
┌────────────────────────────────────────────────────────────────────────┐
│                                                                        │
│            Styled Text:  [ ] Copy basic styles from other apps         │
│                                                                        │
│               Spelling:  [ ] Check as you type                         │
│                                                                        │
│                Tab Key:  (•) Indent lines                              │
│                          ( ) Move typing focus to next field           │
│                          Option-Tab always indents and Shift-Tab       │
│                          always moves the focus backward.              │
│                          [ ] Soft tabs (spaces)                        │
│                                                                        │
│                  Links:  [ ] Make URLs clickable links                 │
│                          [ ] Suggest titles for note-links             │
│                                                                        │
│             URL Import:  [ ] Convert imported URLs to Markdown         │
│                                                                        │
│              Auto-pair:  [ ] Match opening characters, like a left     │
│                              bracket, with closing characters.         │
│                                                                        │
│                 Editor:  [ TextEdit ▾ ]                                │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
```

## Fonts & Colors

```
┌────────────────────────────────────────────────────────────────────────┐
│                                                                        │
│                Body Font:  [ Helvetica 12            ]  { Set… }       │
│                                                                        │
│         Search Highlight:  [ ] Highlight matches        [ color ]      │
│                                                                        │
│   Text and Background Colors affect User Color Scheme only.            │
│                                                                        │
│                                                                        │
│   [x] Always Show Grid Lines in Notes List                             │
│   [ ] Alternating Row Colors                                           │
│                                                                        │
│   [x] Keep Note Body Width Readable                                    │
│      Max. Note Body Width:  [ ====●──────────────── ]  800  pixels     │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
```

---

## Open questions / freeform notes

(Edit / answer below. Anything here overrides the mocks if there's a
conflict.)

- Window content width (px): ?
- Notes › Storage tab: the file-extension and file-type tables share
  a small column of `[+] [-] [★]` square edit buttons. Should I keep
  them visually grouped to the right of each table, or move them
  beneath the tables in a single row?
- Notes › Storage: "Confirm note files removed in the Finder" — keep,
  reword, or drop?
- Notes › Storage: there's a hidden "useFinderTaggingButton" outlet
  declared in code but no matching control in the compiled NIB.
  Should we surface a `[ ] Use Finder Tags` checkbox somewhere on
  this tab, or treat as dead code?
- Notes › Security: "Bits in key" — keep as a numeric stepper, or
  hide entirely (most users won't touch 256)?
- Notes › Security: "Password storage" group — should the radio
  pair sit inside a labeled `NSBox` or just be free-floating like
  the others?
- Anything you want re-grouped (e.g. move "Show menu bar icon" to a
  different pane)?
