//
//  NVAppearance.m
//  Notation
//

#import "NVAppearance.h"

@implementation NVAppearance

+ (BOOL)isDark {
    if (@available(macOS 10.14, *)) {
        NSAppearance *appearance = [NSApp effectiveAppearance];
        NSAppearanceName matched = [appearance bestMatchFromAppearancesWithNames:@[
            NSAppearanceNameAqua,
            NSAppearanceNameDarkAqua,
            NSAppearanceNameAccessibilityHighContrastAqua,
            NSAppearanceNameAccessibilityHighContrastDarkAqua,
        ]];
        return [matched isEqualToString:NSAppearanceNameDarkAqua] ||
               [matched isEqualToString:NSAppearanceNameAccessibilityHighContrastDarkAqua];
    }
    return NO;
}

#pragma mark Editor palette

// Editor surface is intentionally not pure black / pure white — paper-like in
// light mode, slightly elevated above the window in dark mode for legibility.
+ (NSColor *)editorBackgroundColor {
    return [self isDark]
        ? [NSColor colorWithSRGBRed:0.118f green:0.122f blue:0.133f alpha:1.0f]   // ~#1E1F22
        : [NSColor colorWithSRGBRed:0.992f green:0.992f blue:0.988f alpha:1.0f];  // ~#FDFDFC
}

+ (NSColor *)editorTextColor {
    return [self isDark]
        ? [NSColor colorWithSRGBRed:0.898f green:0.902f blue:0.910f alpha:1.0f]   // ~#E5E6E8
        : [NSColor colorWithSRGBRed:0.071f green:0.078f blue:0.094f alpha:1.0f];  // ~#121418
}

+ (NSColor *)editorLinkColor {
    return [self isDark]
        ? [NSColor colorWithSRGBRed:0.466f green:0.741f blue:0.984f alpha:1.0f]   // ~#77BDFB
        : [NSColor colorWithSRGBRed:0.082f green:0.396f blue:0.745f alpha:1.0f];  // ~#1565BE
}

+ (NSColor *)editorInsertionPointColor {
    return [self editorTextColor];
}

+ (NSColor *)editorSearchHighlightColor {
    return [self isDark]
        ? [NSColor colorWithSRGBRed:0.553f green:0.451f blue:0.090f alpha:1.0f]   // amber on dark
        : [NSColor colorWithSRGBRed:1.000f green:0.953f blue:0.616f alpha:1.0f];  // pale yellow on light
}

#pragma mark Table chrome

+ (NSColor *)tableBackgroundColor {
    return [self editorBackgroundColor];
}

+ (NSColor *)tableGridColor {
    return [self isDark]
        ? [NSColor colorWithSRGBRed:0.231f green:0.235f blue:0.247f alpha:1.0f]
        : [NSColor colorWithSRGBRed:0.847f green:0.847f blue:0.835f alpha:1.0f];
}

+ (NSColor *)tableHeaderTextColor {
    return [self isDark]
        ? [NSColor colorWithSRGBRed:0.737f green:0.745f blue:0.761f alpha:1.0f]
        : [NSColor colorWithSRGBRed:0.235f green:0.243f blue:0.259f alpha:1.0f];
}

+ (NSColor *)tableHeaderBackgroundColor {
    return [self isDark]
        ? [NSColor colorWithSRGBRed:0.157f green:0.161f blue:0.176f alpha:1.0f]
        : [NSColor colorWithSRGBRed:0.937f green:0.937f blue:0.929f alpha:1.0f];
}

+ (NSColor *)tableDateTintColor {
    return [self isDark]
        ? [NSColor colorWithSRGBRed:0.612f green:0.620f blue:0.643f alpha:1.0f]
        : [NSColor colorWithSRGBRed:0.420f green:0.439f blue:0.475f alpha:1.0f];
}

#pragma mark Divider

+ (NSColor *)dividerBackgroundColor {
    return [self tableHeaderBackgroundColor];
}

+ (NSColor *)dividerForegroundColor {
    return [self tableGridColor];
}

#pragma mark Field

+ (NSColor *)fieldBackgroundColor {
    return [self isDark]
        ? [NSColor colorWithSRGBRed:0.176f green:0.184f blue:0.200f alpha:1.0f]
        : [NSColor colorWithSRGBRed:1.000f green:1.000f blue:1.000f alpha:1.0f];
}

+ (NSColor *)fieldTextColor {
    return [self editorTextColor];
}

#pragma mark Status bar

+ (NSString *)statusBarIconName {
    // macOS handles template-image inversion for menu-bar items automatically
    // when the asset is a template image, so we ship the same image in both
    // appearances. The "Dark" naming is historical (originally meant "use on
    // dark menu bars") — we keep it for compatibility with existing assets.
    return @"nvMenuDark";
}

@end
