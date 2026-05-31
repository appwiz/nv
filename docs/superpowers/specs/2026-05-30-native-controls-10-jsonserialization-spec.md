# Native Controls Migration 10 — BSJSONAdditions → NSJSONSerialization

Date: 2026-05-30
Status: spec
Component: the `JSON/` folder
(`BSJSONEncoder`, `NSArray+BSJSONAdditions`,
`NSDictionary+BSJSONAdditions`, `NSScanner+BSJSONAdditions`,
`NSString+BSJSONAdditions` — ten files) which provided JSON
encode/decode before Apple shipped `NSJSONSerialization` in 10.7.

## Problem

The codebase uses two methods from the vendored library:

- **Encode** — `-[NSDictionary jsonStringValue]`,
  `-[NSArray jsonStringValue]`, `-[NSString jsonStringValue]`,
  `-[NSNumber jsonStringValue]`. Used in 6 places across
  `SimplenoteEntryCollector.m`, `SimplenoteSession.m`, and
  `NotationPrefsViewController.m` to produce the POST body for
  Simplenote API calls.
- **Decode** — `+[NSDictionary dictionaryWithJSONString:]`. Used in
  5 places across the same files to parse the API responses.

Everything else in the library
(`BSJSONEncoder`, `NSScanner+BSJSONAdditions`, the indent-level
variants on the encoders) is internal plumbing.

Foundation's `NSJSONSerialization` (10.7+) covers both operations
with one well-tested public API.

## Approach

Add a small Foundation-only helper category to keep the call-site
shape similar:

```objc
@interface NSDictionary (NVJSON)
- (NSData *)nv_jsonData;     // UTF-8 encoded JSON
- (NSString *)nv_jsonString; // UTF-8 string
@end

@interface NSArray (NVJSON)
- (NSData *)nv_jsonData;
@end

NSDictionary *NVDictionaryFromJSONString(NSString *s);
```

Backed by `NSJSONSerialization`.

Then walk the call sites:

1. **POST bodies.** Replace
   `[[obj jsonStringValue] dataUsingEncoding:NSUTF8StringEncoding]`
   with `[obj nv_jsonData]`. Cleaner.
2. **Responses.** Replace
   `[NSDictionary dictionaryWithJSONString:bodyString]` with
   `NVDictionaryFromJSONString(bodyString)`.
3. Remove every `#import "NSDictionary+BSJSONAdditions.h"` (and any
   other `JSON/` headers — none of the other classes are imported
   directly).

After all call sites are migrated:

4. Delete the ten files in `JSON/`.
5. Strip their entries from `Notation.xcodeproj/project.pbxproj`.

## Files affected

- new:
  - `NVJSON.h`, `NVJSON.m` — the helper category + decode function.
  - `docs/superpowers/specs/...-10-jsonserialization-spec.md`,
    `docs/native-controls/10-jsonserialization.md`.
- modified:
  - `SimplenoteEntryCollector.m`
  - `SimplenoteSession.m`
  - `NotationPrefsViewController.m`
  - `Notation.xcodeproj/project.pbxproj`
- deleted:
  - `JSON/BSJSONEncoder.{h,m}`
  - `JSON/NSArray+BSJSONAdditions.{h,m}`
  - `JSON/NSDictionary+BSJSONAdditions.{h,m}`
  - `JSON/NSScanner+BSJSONAdditions.{h,m}`
  - `JSON/NSString+BSJSONAdditions.{h,m}`

## Risks / open questions

- The vendored encoder and `NSJSONSerialization` may serialize edge
  cases differently (e.g. number precision, `NSNull` handling). The
  Simplenote API sends/receives well-formed JSON of dictionaries
  with strings, integers, and arrays — the lowest-common-denominator
  surface, where the two encoders agree.
- The decoder needs to handle errors. The old call site swallowed
  parse failures (returned `nil`). The helper does the same:
  returns `nil` on error, no exception propagation.

## Verification

- arm64 build succeeds.
- App launches; Simplenote sync (if a user has it configured) still
  authenticates, fetches the note list, and round-trips a note edit.
  Network-side behaviour is unchanged.
