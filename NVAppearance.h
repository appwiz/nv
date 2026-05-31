//
//  NVAppearance.h
//  Notation
//
//  System-appearance-aware color provider. All custom-drawn UI in the app
//  goes through these accessors so that switching the system between Aqua
//  and Dark Aqua re-themes the whole app via a single observation point.
//
//  This intentionally returns explicit NSColor instances (not the +textColor /
//  +textBackgroundColor dynamic colors) because the editor wants a slightly
//  warmer/colder pair than the system defaults and the existing color-piping
//  code stores resolved NSColor values on individual views.
//
//  Resolution happens once at call time against [NSApp effectiveAppearance];
//  callers should re-fetch on appearance changes (AppController does this in
//  its NSWindowDelegate / NSAppearanceCustomization callbacks).
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NVAppearance : NSObject

// YES iff [NSApp effectiveAppearance] best-matches one of the dark appearance
// names (including high-contrast variants). Falls back to NO on pre-10.14.
+ (BOOL)isDark;

// Editor / notes-table palette
+ (NSColor *)editorBackgroundColor;
+ (NSColor *)editorTextColor;
+ (NSColor *)editorLinkColor;
+ (NSColor *)editorInsertionPointColor;
+ (NSColor *)editorSearchHighlightColor;

// Notes table chrome
+ (NSColor *)tableBackgroundColor;
+ (NSColor *)tableGridColor;
+ (NSColor *)tableHeaderTextColor;
+ (NSColor *)tableHeaderBackgroundColor;
+ (NSColor *)tableDateTintColor;

// Split-view divider
+ (NSColor *)dividerBackgroundColor;
+ (NSColor *)dividerForegroundColor;

// Field/search bar
+ (NSColor *)fieldBackgroundColor;
+ (NSColor *)fieldTextColor;

// Status bar item ("nvMenu" templates), name to pass to +[NSImage imageNamed:].
+ (NSString *)statusBarIconName;

NS_ASSUME_NONNULL_END

@end
