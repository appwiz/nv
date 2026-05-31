# Native Controls 15 — ODBEditor (not applicable)

Status: **not in scope**. No code change.

## What ODBEditor is

The `ODBEditor/` folder (6 files: `ODBEditor.h/.m`,
`NSAppleEventDescriptor-Extensions.h/.m`, `ODBEditorSuite.h`,
`LICENSE.txt`) is an implementation of the *Open Document Bundle
Editor Suite* — a documented Apple Event protocol that lets one app
hand a file to another app for editing and receive a notification
back when the user saves or closes it.

It's how the "edit this note in BBEdit / TextMate / Coda" feature
in nvALT round-trips: the app writes a temp file, fires an `'odb '`
AppleEvent at the chosen editor, and listens for the editor's
`'odbm'` reply when the file is saved.

The receivers (BBEdit, TextMate 2, Coda, Sublime Text, …) still
implement this protocol today.

## Why this isn't an AppKit-migration target

The goal of this migration batch is replacing **custom UI / control
code** with system AppKit equivalents. `ODBEditor` is neither:

- It's not UI — there are no views, cells, windows, or drawing
  code in the entire folder.
- It's not a control — it's an IPC client implementing a
  documented protocol that AppKit has no equivalent for.

The nearest AppKit replacements would be:

- `NSWorkspace -openFile:withApplication:` — opens the file in the
  chosen editor but provides no notification when the user saves
  or closes. The "live sync" UX of edit-externally would silently
  break for every supported editor.
- `NSFilePresenter` + `NSFileCoordinator` — file-system-level
  monitoring. Works in principle but degrades the contract from
  "the editor told us it saved" to "we noticed the file mtime
  changed." Subject to race conditions during save-then-close, and
  doesn't survive the editor moving the file.

Both are functional downgrades for what `ODBEditor` does. Apple
hasn't deprecated `'odb '` events; the protocol is still the
documented mechanism for this exact UX.

## Decision

Leave the ODBEditor folder as-is. The class is small (~700 lines
total), self-contained (only `ExternalEditorListController` and
`NotationController` call into it), and implements a still-current
protocol.

If the project ever drops external-editor support, the folder can
be removed wholesale. Otherwise, it should stay.

## Summary

`ODBEditor/` stays. This entry exists so the change-record sequence
is complete and so future contributors don't waste time hunting for
an "AppKit equivalent" that doesn't exist.
