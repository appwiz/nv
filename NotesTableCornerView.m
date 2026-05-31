//
//  NotesTableCornerView.m
//  Notation
//
//  The notes table's top-right corner view. Re-resolves its colors from
//  NVAppearance every draw so it follows the system appearance.
//

#import "NotesTableCornerView.h"
#import "NVAppearance.h"

@implementation NotesTableCornerView

- (void)drawRect:(NSRect)dirtyRect {
    NSColor *fill = [NVAppearance tableCornerFillColor];
    NSColor *border = [NVAppearance tableCornerBorderColor];

    [fill set];
    NSRectFill(dirtyRect);

    [border setStroke];
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(NSMinX(dirtyRect), NSMaxY(dirtyRect))];
    [path lineToPoint:NSMakePoint(NSMinX(dirtyRect), NSMinY(dirtyRect))];
    [path lineToPoint:NSMakePoint(NSMaxX(dirtyRect), NSMinY(dirtyRect))];
    [path setLineWidth:1.0];
    [path stroke];
}

// Legacy entry points kept as no-ops so any stale callers don't crash.
+ (void)setBackColor:(NSColor *)inColor { (void)inColor; }
+ (void)setBordColor:(NSColor *)inColor { (void)inColor; }

@end
