//
//  StatusBarView.m
//

#import "StatusBarView.h"

#define kSidePadding   12.0
#define kInnerPadding   8.0
#define kFontButtonW  170.0
#define kGearButtonW   24.0
#define kLockSize      14.0

@implementation StatusBarView

@synthesize fontDelegate;

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;

    [self buildSubviews];
    return self;
}

- (void)buildSubviews {
    CGFloat h = self.bounds.size.height;

    // Lock indicator (left side, leftmost)
    NSRect lockFrame = NSMakeRect(kSidePadding,
                                  (h - kLockSize) / 2.0,
                                  kLockSize, kLockSize);
    lockImageView = [[NSImageView alloc] initWithFrame:lockFrame];
    [lockImageView setImageScaling:NSImageScaleProportionallyUpOrDown];
    [lockImageView setAutoresizingMask:NSViewMaxXMargin];
    if (@available(macOS 11.0, *)) {
        NSImage *img = [NSImage imageWithSystemSymbolName:@"lock.open"
                                 accessibilityDescription:@"Notes are not encrypted"];
        [lockImageView setImage:img];
        [lockImageView setContentTintColor:[NSColor secondaryLabelColor]];
    }
    [lockImageView setToolTip:NSLocalizedString(@"Notes are not encrypted", nil)];
    [self addSubview:lockImageView];

    // Note count (just to the right of the lock)
    CGFloat countX = NSMaxX(lockFrame) + kInnerPadding;
    noteCountField = [[NSTextField alloc] initWithFrame:NSMakeRect(countX, 0, 200, h)];
    [noteCountField setBezeled:NO];
    [noteCountField setDrawsBackground:NO];
    [noteCountField setEditable:NO];
    [noteCountField setSelectable:NO];
    [noteCountField setFont:[NSFont systemFontOfSize:11]];
    [noteCountField setTextColor:[NSColor secondaryLabelColor]];
    [noteCountField setStringValue:@""];
    [[noteCountField cell] setLineBreakMode:NSLineBreakByTruncatingTail];
    [noteCountField setAutoresizingMask:NSViewMaxXMargin];
    [self addSubview:noteCountField];

    // Gear button (right side, rightmost)
    CGFloat gearX = self.bounds.size.width - kSidePadding - kGearButtonW;
    NSRect gearFrame = NSMakeRect(gearX, (h - 22) / 2.0, kGearButtonW, 22);
    gearButton = [[NSButton alloc] initWithFrame:gearFrame];
    [gearButton setBezelStyle:NSBezelStyleRecessed];
    [gearButton setShowsBorderOnlyWhileMouseInside:YES];
    [gearButton setTitle:@""];
    if (@available(macOS 11.0, *)) {
        NSImage *gear = [NSImage imageWithSystemSymbolName:@"gearshape"
                                  accessibilityDescription:@"Encryption settings"];
        [gearButton setImage:gear];
    } else {
        [gearButton setTitle:@"⚙"]; // ⚙
    }
    [gearButton setImagePosition:NSImageOnly];
    [gearButton setAutoresizingMask:NSViewMinXMargin];
    [gearButton setToolTip:NSLocalizedString(@"Encryption settings", nil)];
    [self addSubview:gearButton];

    // Body font button (right side, left of gear)
    CGFloat fontX = NSMinX(gearFrame) - kInnerPadding - kFontButtonW;
    NSRect fontFrame = NSMakeRect(fontX, (h - 22) / 2.0, kFontButtonW, 22);
    bodyFontButton = [[NSButton alloc] initWithFrame:fontFrame];
    [bodyFontButton setBezelStyle:NSBezelStyleRecessed];
    [bodyFontButton setShowsBorderOnlyWhileMouseInside:YES];
    [bodyFontButton setFont:[NSFont systemFontOfSize:11]];
    [[bodyFontButton cell] setLineBreakMode:NSLineBreakByTruncatingTail];
    [bodyFontButton setTitle:@""];
    [bodyFontButton setAlignment:NSTextAlignmentRight];
    [bodyFontButton setAutoresizingMask:NSViewMinXMargin];
    [bodyFontButton setToolTip:NSLocalizedString(@"Change body font", nil)];
    [self addSubview:bodyFontButton];
}

- (BOOL)isFlipped {
    return NO;
}

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (void)changeFont:(id)sender {
    NSFontManager *fm = [NSFontManager sharedFontManager];
    NSFont *current = [fm selectedFont];
    if (!current) current = [NSFont systemFontOfSize:12];
    NSFont *newFont = [fm convertFont:current];
    if (fontDelegate) {
        [fontDelegate statusBarView:self didReceiveFontChange:newFont];
    }
}

- (NSUInteger)validModesForFontPanel:(NSFontPanel *)fontPanel {
    return NSFontPanelSizeModeMask | NSFontPanelCollectionModeMask;
}

- (void)drawRect:(NSRect)dirtyRect {
    // Faint top separator only; bar inherits window background.
    [[NSColor separatorColor] set];
    NSRect line = NSMakeRect(0, self.bounds.size.height - 1, self.bounds.size.width, 1);
    NSRectFill(line);
}

- (void)setBodyFont:(NSFont *)font {
    if (!font) {
        [bodyFontButton setTitle:NSLocalizedString(@"Body Font…", nil)];
        return;
    }
    NSString *label = [NSString stringWithFormat:@"%@ %.0f",
                       [font displayName], [font pointSize]];
    [bodyFontButton setTitle:label];
}

- (void)setEncrypted:(BOOL)encrypted {
    NSString *symbolName = encrypted ? @"lock.fill" : @"lock.open";
    NSString *tip = encrypted
        ? NSLocalizedString(@"Notes are encrypted", nil)
        : NSLocalizedString(@"Notes are not encrypted", nil);
    if (@available(macOS 11.0, *)) {
        NSImage *img = [NSImage imageWithSystemSymbolName:symbolName
                                 accessibilityDescription:tip];
        [lockImageView setImage:img];
        [lockImageView setContentTintColor:
            encrypted ? [NSColor labelColor] : [NSColor secondaryLabelColor]];
    }
    [lockImageView setToolTip:tip];
}

- (void)setNoteCount:(NSUInteger)count {
    NSString *fmt = (count == 1)
        ? NSLocalizedString(@"%lu note", nil)
        : NSLocalizedString(@"%lu notes", nil);
    [noteCountField setStringValue:
        [NSString stringWithFormat:fmt, (unsigned long)count]];
}

- (void)setBodyFontTarget:(id)target action:(SEL)action {
    [bodyFontButton setTarget:target];
    [bodyFontButton setAction:action];
}

- (void)setGearTarget:(id)target action:(SEL)action {
    [gearButton setTarget:target];
    [gearButton setAction:action];
}

- (void)setGearMenu:(NSMenu *)menu {
    [gearButton setMenu:menu];
}

- (void)dealloc {
    [bodyFontButton release];
    [lockImageView release];
    [noteCountField release];
    [gearButton release];
    [super dealloc];
}

@end
