# Native Controls 17 — Editor URL auto-link + preview wiki links

Follow-ups to the arm64 port's "AutoHyperlinks disabled" gap and to
a long-standing gap in the preview pipeline.

## Problems

1. **Typing a URL in the editor doesn't make it clickable.** The
   Apple Silicon port disabled `AutoHyperlinks` (no arm64 slice in
   the bundled framework) and the runtime path in
   `AttributedPlainText -addLinkAttributesForRange:` was left in
   its lazy-load form, which now always early-returns. URL auto-
   detection is silently a no-op.

2. **`[[Wiki-style links]]` render as plain text in the Markdown
   preview.** The editor decorates `[[Title]]` with a
   `nvalt://find/Title` link (see
   `AttributedPlainText -_addDoubleBracketedNVLinkAttributesForRange:`),
   but the preview pipeline sends the raw note text straight to the
   Markdown / MultiMarkdown processor — and neither engine
   understands `[[…]]` syntax. The preview shows the brackets
   verbatim.

## Fixes

### URL auto-detection via NSDataDetector

`AttributedPlainText -addLinkAttributesForRange:` is rewritten to
use Foundation's `NSDataDetector` with `NSTextCheckingTypeLink`:

```objc
NSDataDetector *detector = …NSTextCheckingTypeLink…;
[detector enumerateMatchesInString:substring … usingBlock:^(result, …) {
    NSURL *url = result.URL;
    if (!url) return;
    if (url.isFileURL &&
        [url.absoluteString rangeOfString:@"/.file/" …].location != NSNotFound) return;
    NSRange range = NSMakeRange(result.range.location + changedRange.location,
                                result.range.length);
    [self addAttribute:NSLinkAttributeName value:url range:range];
}];
[self _addDoubleBracketedNVLinkAttributesForRange:changedRange];
```

The detector is created once and cached in a static. The same
"skip `file:///.file/` pseudo-URLs" rule from the old code path is
preserved (Foundation occasionally produces those for
sandbox-style paths and they're not useful as clickable links).

### Preview wiki-link preprocessing

A new class method `+[PreviewController preprocessNVWikiLinks:]`
runs the raw note text through a single regex pass before the
Markdown processor sees it:

```
[[Title]]   →   [Title](nvalt://find/Title)
```

The pattern is `\[\[([^\[\]\n]+?)\]\]` (non-greedy so adjacent
`[[a]][[b]]` doesn't merge). The title is URL-encoded with
`URLPathAllowedCharacterSet`. The downstream Markdown engine emits
a normal `<a href="nvalt://find/Title">Title</a>`, so the preview
shows the link styled and clickable — and using the **same scheme**
as the editor's in-place link decoration, so existing click handlers
keep working.

## Files

- **modified**
  - `AttributedPlainText.m` — `-addLinkAttributesForRange:` rewritten
    around `NSDataDetector`; the `_addDoubleBracketedNVLinkAttributesForRange:`
    call afterwards is preserved.
  - `PreviewController.m` — `-requestPreviewUpdate:` (or wherever
    `rawString = [app noteContent]` is the input to the processor)
    now passes `rawString` through `+preprocessNVWikiLinks:` first.
    Added the new class method.

## Verification

- arm64 build succeeds.
- App launches.
- Typing `https://example.com` in a note auto-links the URL.
- A note containing `[[Some Note]]` shows the wiki link as a
  styled, clickable hyperlink in the preview window.

## Reverting

`git revert <hash>` restores the prior AutoHyperlinks lazy-load
path and removes the preview preprocessing.
