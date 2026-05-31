//
//  NotesTableHeaderCell.m
//  Notation
//
//  System-appearance-aware header cell. Colors come from NVAppearance on each
//  draw so live appearance changes don't require any external bookkeeping.
//

#import "NotesTableHeaderCell.h"
#import "NVAppearance.h"

@interface NotesTableHeaderCell (Private)
- (void)_drawBorderInRect:(NSRect)cellFrame;
- (void)_drawFillInRect:(NSRect)cellFrame;
@end

@implementation NotesTableHeaderCell

- (id)initTextCell:(NSString *)text {
    if ((self = [super initTextCell:text])) {
        if (!text || text.length == 0) {
            [self setTitle:@"Title"];
        }
    }
    return self;
}

- (BOOL)isOpaque {
    return YES;
}

- (NSRect)drawingRectForBounds:(NSRect)theRect {
    return NSIntegralRect(NSInsetRect(theRect, 6.0f, 1.0f));
}

- (NSRect)sortIndicatorRectForBounds:(NSRect)theRect {
    theRect = [super sortIndicatorRectForBounds:theRect];
    theRect.origin.y = floor(theRect.origin.y - 0.5f);
    return NSIntegralRect(theRect);
}

- (void)drawWithFrame:(NSRect)inFrame inView:(NSView *)inView {
    [self setTextColor:[NVAppearance tableHeaderTextColor]];
    [self _drawFillInRect:inFrame];
    [self drawInteriorWithFrame:inFrame inView:inView];
    [self _drawBorderInRect:inFrame];
}

#define kSelectedCellEmphasisLevel 0.18f

- (void)highlight:(BOOL)hBool withFrame:(NSRect)inFrame inView:(NSView *)controlView {
    NSColor *base = [NVAppearance tableHeaderBackgroundColor];
    NSColor *fill = [NVAppearance isDark]
        ? [base highlightWithLevel:kSelectedCellEmphasisLevel]
        : [base shadowWithLevel:kSelectedCellEmphasisLevel];
    [self setTextColor:[NVAppearance tableHeaderTextColor]];
    [fill set];
    NSRectFill(inFrame);
    [self drawInteriorWithFrame:inFrame inView:controlView];
    [self _drawBorderInRect:inFrame];
}

#pragma mark - legacy class-level color setters (now no-ops)

+ (void)setBColor:(NSColor *)inColor { (void)inColor; }
+ (void)setTxtColor:(NSColor *)inColor { (void)inColor; }

@end

@implementation NotesTableHeaderCell (Private)

- (void)_drawFillInRect:(NSRect)cellFrame {
    [[NVAppearance tableHeaderBackgroundColor] set];
    NSRectFill(cellFrame);
}

- (void)_drawBorderInRect:(NSRect)cellFrame {
    NSColor *border = [NVAppearance tableGridColor];
    NSBezierPath *path = [NSBezierPath bezierPath];
    NSPoint base = NSMakePoint(cellFrame.origin.x, NSMaxY(cellFrame) - 0.5f);
    [path moveToPoint:NSMakePoint(NSMaxX(cellFrame), base.y)];
    [path lineToPoint:base];

    if (cellFrame.origin.x > 5.0f) {
        // vertical column-separator on non-leading columns
        [path moveToPoint:NSMakePoint(cellFrame.origin.x, NSMaxY(cellFrame))];
        [path lineToPoint:cellFrame.origin];
    }
    [border setStroke];
    [path setLineWidth:1.0f];
    [path stroke];
}

@end
