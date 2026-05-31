//
//  StatusBarView.h
//  Notational Velocity
//
//  Thin bar pinned at the bottom of the main window. Replaces the
//  Settings (Preferences) window. Two interactive controls:
//
//    - Body font picker (left)            -> -bodyFontButtonClicked:
//    - Encryption gear with menu (right)  -> -gearButtonClicked:
//
//  Two read-only indicators:
//
//    - Lock icon (encrypted yes/no)
//    - Note count text ("347 notes")
//
//  Owner (AppController) sets the target/action for the two buttons,
//  pushes display state via the setters, and supplies the gear menu.
//

#import <Cocoa/Cocoa.h>

#define kStatusBarHeight 28.0

@interface StatusBarView : NSView {
    NSButton *bodyFontButton;
    NSTextField *noteCountField;
    NSButton *gearButton;
}

- (void)setBodyFont:(NSFont *)font;
- (void)setNoteCount:(NSUInteger)count;

- (void)setBodyFontTarget:(id)target action:(SEL)action;
- (void)setGearTarget:(id)target action:(SEL)action;
- (void)setGearMenu:(NSMenu *)menu;

@end
