//
//  NVSplitView.m
//  Notation
//

#import "NVSplitView.h"

@implementation NVSplitView

// Hit-test the divider on double-click and forward to AppController's
// -toggleCollapse: action. The previous RBSplitView delegate handled this
// via -splitView:shouldHandleEvent:; NSSplitView doesn't expose an
// equivalent, but a -mouseDown: override at the divider rect works.
- (void)mouseDown:(NSEvent *)event {
    if ([event clickCount] >= 2) {
        NSPoint loc = [self convertPoint:event.locationInWindow fromView:nil];
        // Walk all divider indices in case future layouts grow more panes.
        for (NSInteger i = 0; i < (NSInteger)self.subviews.count - 1; i++) {
            NSRect divider = NSZeroRect;
            // AppKit doesn't publish per-index divider rects directly, so derive
            // from the leading subview's frame.
            NSView *leading = self.subviews[i];
            if (self.isVertical) {
                divider = NSMakeRect(NSMaxX(leading.frame), 0,
                                     self.dividerThickness, self.bounds.size.height);
            } else {
                divider = NSMakeRect(0, NSMaxY(leading.frame),
                                     self.bounds.size.width, self.dividerThickness);
            }
            if (NSPointInRect(loc, divider)) {
                id target = NSApp.delegate;
                if ([target respondsToSelector:@selector(toggleCollapse:)]) {
                    [target performSelector:@selector(toggleCollapse:) withObject:self];
                }
                return;
            }
        }
    }
    [super mouseDown:event];
}

@end
