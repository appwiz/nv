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

@class StatusBarView;

@protocol StatusBarViewFontDelegate <NSObject>
- (void)statusBarView:(StatusBarView *)bar didReceiveFontChange:(NSFont *)newFont;
@end

@interface StatusBarView : NSView {
    NSButton *bodyFontButton;
    NSImageView *lockImageView;
    NSTextField *noteCountField;
    NSButton *gearButton;
    id<StatusBarViewFontDelegate> fontDelegate; // non-retained
}

@property(assign) id<StatusBarViewFontDelegate> fontDelegate;

- (void)setBodyFont:(NSFont *)font;
- (void)setEncrypted:(BOOL)encrypted;
- (void)setNoteCount:(NSUInteger)count;

- (void)setBodyFontTarget:(id)target action:(SEL)action;
- (void)setGearTarget:(id)target action:(SEL)action;
- (void)setGearMenu:(NSMenu *)menu;

@end
