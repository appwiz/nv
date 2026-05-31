//
//  ETScrollView.h
//  Notation
//
//  Thin NSScrollView subclass that exists only so its scrolling behaviour
//  (autohide, non-elastic horizontal, elastic vertical) can be set in code
//  rather than configured per-XIB across six localizations. AppKit handles
//  the scroller chrome and dark-mode adaptation.
//

#import <Cocoa/Cocoa.h>

@interface ETScrollView : NSScrollView
@end
