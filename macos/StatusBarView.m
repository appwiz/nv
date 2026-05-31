//
//  StatusBarView.m
//

#import "StatusBarView.h"

#define kSidePadding   12.0
#define kInnerPadding   8.0
#define kFontButtonW  170.0
#define kGearButtonW   24.0

@implementation StatusBarView

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;

    [self buildSubviews];
    return self;
}

- (void)buildSubviews {
    CGFloat h = self.bounds.size.height;

    // Note count, leftmost.
    noteCountField = [[NSTextField alloc] initWithFrame:
        NSMakeRect(kSidePadding, 0, 200, h)];
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

    // Gear button, rightmost.
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
        [gearButton setTitle:@"⚙"];
    }
    [gearButton setImagePosition:NSImageOnly];
    [gearButton setAutoresizingMask:NSViewMinXMargin];
    [gearButton setToolTip:NSLocalizedString(@"Encryption settings", nil)];
    [self addSubview:gearButton];

    // Body font button, left of gear.
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

- (void)drawRect:(NSRect)dirtyRect {
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
    [noteCountField release];
    [gearButton release];
    [super dealloc];
}

@end
