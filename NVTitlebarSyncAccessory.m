//
//  NVTitlebarSyncAccessory.m
//  Notation
//

#import "NVTitlebarSyncAccessory.h"

@interface NVTitlebarSyncAccessory ()
@property (nonatomic, retain) NSButton *button;
@property (nonatomic, retain) NSProgressIndicator *spinner;
@end

@implementation NVTitlebarSyncAccessory

- (instancetype)init {
    if ((self = [super init])) {
        // 24-pt-tall accessory anchored to the trailing edge of the title bar.
        self.layoutAttribute = NSLayoutAttributeRight;
        NSView *container = [[[NSView alloc] initWithFrame:NSMakeRect(0, 0, 26.0, 22.0)] autorelease];
        self.view = container;

        // Plain unbordered NSButton. On click we pop the attached menu under
        // the button — this sidesteps NSPopUpButton's pull-down quirks (the
        // popup showing item 0's title next to an arrow indicator).
        _button = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 26.0, 22.0)];
        _button.bordered = NO;
        _button.imagePosition = NSImageOnly;
        _button.title = @"";
        _button.target = self;
        _button.action = @selector(showMenu:);
        _button.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        [container addSubview:_button];

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
    [_button release];
    [_spinner release];
    [_nv_menu release];
    [super dealloc];
}

- (void)setNv_menu:(NSMenu *)menu {
    if (_nv_menu != menu) {
        [_nv_menu release];
        _nv_menu = [menu retain];
    }
}

- (void)showMenu:(id)sender {
    if (!_nv_menu) return;
    NSPoint origin = NSMakePoint(0, NSMaxY(_button.bounds) + 2);
    [_nv_menu popUpMenuPositioningItem:nil atLocation:origin inView:_button];
}

- (void)setIconType:(NVTitlebarSyncIconType)type {
    self.hidden = (type == NVTitlebarSyncIconNone);
    if (type == NVTitlebarSyncIconNone) {
        [_spinner stopAnimation:nil];
        return;
    }

    if (type == NVTitlebarSyncIconSynchronizing) {
        _button.hidden = YES;
        [_spinner startAnimation:nil];
    } else {
        [_spinner stopAnimation:nil];
        _button.hidden = NO;
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
        if (!image && type == NVTitlebarSyncIconAlert) {
            image = [NSImage imageNamed:NSImageNameCaution];
        }
        if (image) {
            image.template = YES;
        }
        _button.image = image;
    }
}

@end
