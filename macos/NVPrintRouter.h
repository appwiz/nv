//
//  NVPrintRouter.h
//  Notation
//
//  Routes the "print selected notes" command into NSPrintOperation. Replaces
//  the 300-line vendored MultiplePageView (Apple TextEdit sample, 1995-2005)
//  that hand-rolled per-page text containers; NSTextView paginates itself
//  when printed under modern AppKit.
//

#import <Cocoa/Cocoa.h>

@interface NVPrintRouter : NSObject
+ (void)printNotes:(NSArray *)notes forWindow:(NSWindow *)window;
@end
