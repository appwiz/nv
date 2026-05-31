# Apple Silicon Native Build Notes

This document records the changes made to get this codebase (last touched
in the Xcode 11 / macOS 10.9 era) building and running as a native
`arm64` binary on a modern Apple Silicon Mac with Xcode 26.5 and the
macOS 26.5 SDK.

The work landed in two commits:

- `c075e2d` — Fix build errors on modern Xcode/macOS SDK (x86_64 under Rosetta)
- `ffb84be` — Build natively for Apple Silicon (arm64)

## Build environment

| Component | Version used |
| --- | --- |
| Xcode | 26.5 (Build 17F42) |
| macOS SDK | MacOSX26.5.sdk |
| Host | Apple Silicon (arm64) |
| Homebrew | `/opt/homebrew` |
| OpenSSL | `openssl@3` from Homebrew (arm64) |

## Build command

```sh
xcodebuild -scheme "Notation Develop" -configuration Development \
  -arch arm64 ONLY_ACTIVE_ARCH=YES \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO build
```

The signing flags are needed because the project's signing identity
references a team ID that isn't installed on this machine. The arch
flag is needed only until the rest of the bundled binaries (Sparkle,
AutoHyperlinks) ship arm64 slices.

## Phase 1 — Get it to compile (commit `c075e2d`)

Modern clang treats implicit function declarations and missing
prototypes as errors, and several CoreFoundation/IOKit/OpenSSL APIs
that the codebase relied on have been renamed, removed, or made
opaque. These edits make the source build under the current SDK.

### `WALController.m`

`CFHashBytes` is no longer available in the public CoreFoundation
headers. The function was used to hash 16-byte `CFUUIDBytes`. Replaced
with an inline XOR of the two 64-bit halves, which is fine for a
hash-table bucket distribution over UUIDs:

```objc
static CFHashCode SynchronizedNoteHash(const void * o) {
    const uint64_t *p = (const uint64_t *)o;
    return (CFHashCode)(p[0] ^ p[1]);
}
```

### `SyncSessionController.m`

The file calls `IOAllowPowerChange`, `IORegisterForSystemPower`,
`IODeregisterForSystemPower`, and `IOCancelPowerChange` but only
imported `IOMessage.h` (commented out at that). Added the two
headers that actually declare these:

```objc
#import <IOKit/IOMessage.h>
#import <IOKit/pwr_mgt/IOPMLib.h>
```

### `RBSplitView/RBSplitView.m`, `EmptyView.m`

Both call `outletObjectAwoke(self)` from `awakeFromNib`, but the
`#import "AppController.h"` line (which declares it) was commented
out. Uncommented in both files.

### `PrefsWindowController.m`, `NSString_CustomTruncation.m`, `GlobalPrefs.m`

Each calls into helpers declared in `BufferUtils.h` (`IsZeros`,
`replace_breaks`, `replace_breaks_utf8`) without importing the
header. Added `#import "BufferUtils.h"` to each.

### `FSExchangeObjectsCompat.h` + `NotationFileManager.m`

`volumeCapabilities` was defined in `FSExchangeObjectsCompat.c` but
never declared in the header. Added a prototype:

```c
u_int32_t volumeCapabilities(const char *path);
```

…and made `NotationFileManager.m` import the header.

### `NSFileManager_NV.m`

Calls `getxattr` / `setxattr` / `removexattr` without
`#include <sys/xattr.h>`. Added the include.

### `NSData_transformations.m`

Two issues:

1. `ERR_error_string(ERR_get_error(), buf, sizeof(buf))` — the
   two-argument `ERR_error_string` doesn't take a length. Switched to
   the bounded variant `ERR_error_string_n`.
2. Missing `<openssl/err.h>`. Added.

### `GlobalPrefs.m`

`IMP` is now strictly typed as `void (*)(void)`; calling it with
arguments needs an explicit cast. Wrapped the call in a typed
function-pointer cast:

```objc
((void (*)(id, SEL, SEL, id))self->runCallbacksIMP)(
    self,
    @selector(notifyCallbacksForSelector:excludingSender:),
    selector, originalSender);
```

Also added `#import "BufferUtils.h"` for `IsZeros`.

### `AppController.m`

Added `#import "NSString_CustomTruncation.h"` so the prototype for
`ResetFontRelatedTableAttributes()` is visible.

### `SimperiumConfig.h`

The project references `SimperiumConfig.h` but only ships
`SimperiumConfig-example.h` (the real one is intentionally gitignored
to keep credentials out of the repo). Created
`SimperiumConfig.h` locally from the example. Not committed.

### Build flags

After these edits the project builds for x86_64 (under Rosetta) with:

```sh
xcodebuild ... -arch x86_64 ONLY_ACTIVE_ARCH=NO \
  MACOSX_DEPLOYMENT_TARGET=10.13 \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO build
```

`MACOSX_DEPLOYMENT_TARGET=10.13` is needed because the project pins
10.9 and modern Xcode no longer ships `libarclite_macosx.a` for
older targets.

## Phase 2 — Native arm64 (commit `ffb84be`)

After Phase 1 the source compiles, but linking for `arm64` fails
because three bundled binaries have no `arm64` slice:

```
ld: warning: ignoring file 'libssl.a': fat file missing arch 'arm64', file has 'i386,x86_64'
ld: warning: ignoring file 'libcrypto.a': fat file missing arch 'arm64', file has 'i386,x86_64'
ld: warning: ignoring file 'AutoHyperlinks.framework/AutoHyperlinks': fat file missing arch 'arm64', file has 'unknown,i386,x86_64'
ld: warning: ignoring file 'Sparkle.framework/Sparkle': fat file missing arch 'arm64', file has 'ppc,i386,x86_64'
```

### OpenSSL — replace with Homebrew openssl@3

The bundled `libssl.a` / `libcrypto.a` in the project root were
PPC/i386/x86_64 only and ABI-pinned to OpenSSL 1.0.2. They were
replaced with the arm64 static libs from
`/opt/homebrew/opt/openssl@3/lib/`.

OpenSSL 3 made `EVP_CIPHER_CTX` and `EVP_MD_CTX` opaque, so they can
no longer be allocated on the stack. `NSData_transformations.m` was
ported to the heap-context API in three places:

- `MD5Digest` — `EVP_MD_CTX_new()` / `EVP_MD_CTX_free()`.
- `encryptDataWithCipher:key:iv:` — `EVP_CIPHER_CTX_new()` + `EVP_CIPHER_CTX_free()`. Replaced the early `return NO` exits with `goto done` so the context is always freed.
- `decryptDataWithCipher:key:iv:` — same conversion.

`EVP_CIPHER_CTX_cleanup` (removed in OpenSSL 3) was replaced with
`EVP_CIPHER_CTX_free`.

`NotationFileManager.m`'s low-level `MD5_CTX` / `MD5_Init` /
`MD5_Update` / `MD5_Final` use still compiles against openssl@3
(deprecation warning only), so it was left alone.

### Header search path ordering

The project ships its own copy of the OpenSSL 1.0 headers in
`library/openssl/`. Those headers shadow Homebrew's via the
`library/**` entry in `HEADER_SEARCH_PATHS`, which made the OpenSSL 3
declarations invisible to the compiler. The fix was to prepend the
Homebrew include directory so it wins. The `@` in `openssl@3` has to
be quoted in `.pbxproj` strings.

```
HEADER_SEARCH_PATHS = (
    "/opt/homebrew/opt/openssl@3/include",
    ICU/icu,
    "$(PROJECT_DIR)/library/**",
);
```

### Sparkle (auto-update) — disabled

`Sparkle.framework` is a fat ppc/i386/x86_64 dylib (Sparkle ~1.5
era), so dyld can't load it into an arm64 process and the linker
can't satisfy `_OBJC_CLASS_$_SUUpdater` for the arm64 slice either.
Pulling in a modern arm64-capable Sparkle would be the right
long-term fix; for now the integration is stubbed out:

- Removed `#import <Sparkle/SUUpdater.h>` from `AppController.m`.
- Replaced the `applicationDidFinishLaunching` block that loaded
  Sparkle and configured `SUUpdater` with two lines that hide and
  disable the "Check for Updates" menu item.
- Removed `Sparkle.framework` from the Frameworks build phase and
  the Copy Files (Frameworks) phase in `Notation.xcodeproj/project.pbxproj`.

The framework directory itself is still in the working tree — it just
isn't linked or copied into the .app any more.

### AutoHyperlinks — disabled

`AutoHyperlinks.framework` has the same problem (ppc_7400/i386/x86_64
only, no arm64). The runtime code in `AttributedPlainText.m` was
already defensively coded to load the framework via `NSBundle` and
look up classes via `NSClassFromString`, so the only changes needed
were:

- Removed `#import <AutoHyperlinks/AutoHyperlinks.h>` (the header is
  inside the framework and not on the new header search paths).
- Removed `AutoHyperlinks.framework` from the Frameworks build phase
  and the Copy Files phase in `Notation.xcodeproj/project.pbxproj`.

URL auto-detection in note bodies is silently skipped — the runtime
load fails, `NSClassFromString` returns `Nil`, and the
`while ([scanner nextURI])` loop becomes a no-op because messaging
`nil` returns `nil`.

### Other xcodeproj changes

- Removed the orphan `LIBRARY_SEARCH_PATHS = /usr/local/Cellar/openssl/1.0.2/lib/` and reset it back to `$(PROJECT_DIR)` in both `Development` and `ForBuilding` configurations.
- Bumped `MACOSX_DEPLOYMENT_TARGET` from 10.9 to 10.13 in both
  configurations so the arclite-runtime requirement is satisfied
  without needing it on the command line.

## Verifying the result

```sh
file build/.../nvALT.app/Contents/MacOS/nvALT
# Mach-O 64-bit executable arm64

lipo -archs build/.../nvALT.app/Contents/MacOS/nvALT
# arm64
```

Launching the .app produces a process that, since the binary has no
x86_64 slice, can only be running natively under arm64 — not under
Rosetta.

## Known regressions

| Feature | Status | To restore |
| --- | --- | --- |
| Auto-update via Sparkle | Disabled | Replace `Sparkle.framework` with a modern arm64-capable build (Sparkle 1.27.x is the last 1.x release that supports arm64; Sparkle 2.x has API changes) and revert the `AppController.m` stub and the xcodeproj framework removals. |
| URL auto-detection in notes | Disabled | Rebuild `AutoHyperlinks.framework` from the [adium-im sources](https://hg.adium.im/adium/) for arm64 and re-add to the project. As a lighter-weight alternative, replace the call sites in `AttributedPlainText.m` with `NSDataDetector`. |
| `SimperiumConfig.h` | Not under version control | Copy `SimperiumConfig-example.h` to `SimperiumConfig.h` locally; populate with real credentials if Simplenote sync is needed. |
| Code signing | Disabled | A valid Developer ID / Mac Development cert plus matching team ID is required to ship a distributable build. The current build is unsigned and is only suitable for local use. |
| OpenSSL deprecation warnings | Cosmetic | `EVP_DigestInit`, `EVP_EncryptInit`, `MD5_Init`/`MD5_Update`/`MD5_Final` etc. all emit `-Wdeprecated-declarations` warnings against OpenSSL 3. The functions still work; migrating to the `_ex2` variants or to Apple's `CommonCrypto` would silence them. |
