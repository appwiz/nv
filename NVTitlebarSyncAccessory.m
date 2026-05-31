//
//  NVTitlebarSyncAccessory.m
//  Notation
//

#import "NVTitlebarSyncAccessory.h"

@interface NVTitlebarSyncAccessory ()
@property (nonatomic, retain) NSPopUpButton *popup;
@property (nonatomic, retain) NSProgressIndicator *spinner;
@end

@implementation NVTitlebarSyncAccessory

- (instancetype)init {
    if ((self = [super init])) {
        // 24-pt-tall accessory anchored to the trailing edge of the title bar.
        self.layoutAttribute = NSLayoutAttributeRight;
        NSView *container = [[[NSView alloc] initWithFrame:NSMakeRect(0, 0, 26.0, 22.0)] autorelease];
        self.view = container;

        _popup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(0, 0, 26.0, 22.0)
                                            pullsDown:YES];
        _popup.bordered = NO;
        _popup.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        // Empty first item (pull-down buttons show this item's image as the icon).
        [_popup addItemWithTitle:@""];
        [container addSubview:_popup];

        _spinner = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(5.0, 3.0, 16.0, 16.0)];
        _spinner.style = NSProgressIndicatorStyleSpinning;
        _spinner.controlSize = NSControlSizeSmall;
        _spinner.indeterminate = YES;
        _spinner.displayedWhenStopped = NO;
        [container addSubview:_spinner];

        [self setIconType:NVTitlebarSyncIconNone];
    }
    return self;
}

- (void)dealloc {
    [_popup release];
    [_spinner release];
    [_nv_menu release];
    [super dealloc];
}

- (void)setNv_menu:(NSMenu *)menu {
    if (_nv_menu != menu) {
        [_nv_menu release];
        _nv_menu = [menu retain];
    }
    // Pull-down button uses its menu for the popped-down options. Item 0 of the
    // attached menu must stay empty so the button shows the icon, not text.
    NSMenu *withHidden = [[[NSMenu alloc] init] autorelease];
    [withHidden addItem:[[[NSMenuItem alloc] init] autorelease]];
    if (menu) {
        for (NSMenuItem *item in menu.itemArray) {
            NSMenuItem *copy = [item copy];
            [withHidden addItem:copy];
            [copy release];
        }
    }
    _popup.menu = withHidden;
}

- (void)setIconType:(NVTitlebarSyncIconType)type {
    self.hidden = (type == NVTitlebarSyncIconNone);
    if (type == NVTitlebarSyncIconNone) {
        [_spinner stopAnimation:nil];
        return;
    }

    if (type == NVTitlebarSyncIconSynchronizing) {
        _popup.hidden = YES;
        [_spinner startAnimation:nil];
    } else {
        [_spinner stopAnimation:nil];
        _popup.hidden = NO;
        NSImage *image = nil;
        if (@available(macOS 11.0, *)) {
            if (type == NVTitlebarSyncIconChevron) {
                image = [NSImage imageWithSystemSymbolName:@"chevron.down.circle"
                                  accessibilityDescription:@"Sync menu"];
            } else if (type == NVTitlebarSyncIconAlert) {
                image = [NSImage imageWithSystemSymbolName:@"exclamationmark.triangle.fill"
                                  accessibilityDescription:@"Sync error"];
            }
        }
        if (!image) {
            // Pre-11 fallback. NSCaution is always present; for the chevron we use
            // a small triangle as a stand-in (the legacy bundled images aren't
            // appearance-aware).
            image = (type == NVTitlebarSyncIconAlert)
                ? [NSImage imageNamed:NSImageNameCaution]
                : nil;
        }
        if (image) {
            image.template = YES;
        }
        // The pull-down button's image comes from item 0.
        [[_popup itemAtIndex:0] setImage:image];
    }
}

@end
