# Native Controls 10 — BSJSONAdditions → NSJSONSerialization

Companion to `docs/superpowers/specs/2026-05-30-native-controls-10-jsonserialization-spec.md`.

## What changed

The vendored `BSJSONAdditions` JSON library (ten files in `JSON/`)
is deleted. JSON encode and decode now go through Foundation's
`NSJSONSerialization` (10.7+).

## How

A small Foundation-only helper file, `NVJSON.h`/`NVJSON.m`, exposes
three things:

| API | Behaviour |
| --- | --- |
| `-[NSDictionary nv_jsonData]` | UTF-8 JSON `NSData` for a JSON-safe dictionary, `nil` otherwise. |
| `-[NSDictionary nv_jsonString]` | UTF-8 `NSString` form of the same. |
| `-[NSArray nv_jsonData]` | UTF-8 JSON `NSData` for a JSON-safe array. |
| `NVDictionaryFromJSONString(s)` | Parses `s`; returns the dictionary, or `nil` on malformed JSON / non-dictionary top level. |

Each is a one-liner wrapping `NSJSONSerialization`.

The Simplenote API surface uses two old idioms, replaced one-to-one:

- `[obj jsonStringValue] dataUsingEncoding:NSUTF8StringEncoding]` →
  `[obj nv_jsonData]` (also drops the double-conversion).
- `[NSDictionary dictionaryWithJSONString:s]` →
  `NVDictionaryFromJSONString(s)`.

## Files

- **new**
  - `NVJSON.h`, `NVJSON.m`.
  - `docs/native-controls/10-jsonserialization.md`.
  - `docs/superpowers/specs/2026-05-30-native-controls-10-jsonserialization-spec.md`.
- **modified**
  - `SimplenoteSession.m` — swap import, 1 encode + 3 decode
    call sites.
  - `SimplenoteEntryCollector.m` — swap import, 2 encode + 2 decode
    call sites.
  - `NotationPrefsViewController.m` — add `#import "NVJSON.h"` (was
    using the additions transitively through `SimplenoteSession.h`),
    1 encode call site.
  - `Notation.xcodeproj/project.pbxproj` — add the two NVJSON
    entries; remove the entire `BSJSON` group (10 PBXFileReference
    entries, 5 PBXBuildFile entries, 1 PBXGroup, 5 entries in the
    Sources build phase).
- **deleted (10)** — the whole `JSON/` folder:
  - `JSON/BSJSONEncoder.{h,m}`
  - `JSON/NSArray+BSJSONAdditions.{h,m}`
  - `JSON/NSDictionary+BSJSONAdditions.{h,m}`
  - `JSON/NSScanner+BSJSONAdditions.{h,m}`
  - `JSON/NSString+BSJSONAdditions.{h,m}`

## Verification

- arm64 build succeeds.
- App launches.
- Simplenote sync (if configured) round-trips login + note edits;
  network-side behaviour is unchanged because both encoders agree
  on the JSON shape used by the API (dictionaries of strings,
  integers, and arrays).

## Reverting

`git revert <hash>` restores the JSON folder, the pbxproj entries,
and the prior call sites in the three Simplenote files.
