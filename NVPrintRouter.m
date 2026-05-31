//
//  NVPrintRouter.m
//  Notation
//

#import "NVPrintRouter.h"
#import "NoteObject.h"
#import "GlobalPrefs.h"

@implementation NVPrintRouter

+ (void)printNotes:(NSArray *)notes forWindow:(NSWindow *)window {
    if (notes.count == 0) return;

    NSFont *bodyFont = [[GlobalPrefs defaultPrefs] noteBodyFont];

    NSMutableAttributedString *document =
        [[[NSMutableAttributedString alloc] init] autorelease];
    NSAttributedString *formFeed =
        [[[NSAttributedString alloc] initWithString:@"\f"] autorelease];

    for (NSUInteger i = 0; i < notes.count; i++) {
        NoteObject *note = notes[i];
        [document appendAttributedString:[note printableStringRelativeToBodyFont:bodyFont]];
        if (i + 1 < notes.count) {
            [document appendAttributedString:formFeed];
        }
    }

    NSPrintInfo *info = [NSPrintInfo sharedPrintInfo];
    NSSize paper = info.paperSize;
    NSRect textFrame = NSMakeRect(0, 0,
                                  paper.width - info.leftMargin - info.rightMargin,
                                  paper.height - info.topMargin - info.bottomMargin);

    NSTextView *textView = [[[NSTextView alloc] initWithFrame:textFrame] autorelease];
    [textView.textStorage setAttributedString:document];

    NSPrintOperation *op = [NSPrintOperation printOperationWithView:textView
                                                          printInfo:info];
    [op runOperationModalForWindow:window
                          delegate:nil
                    didRunSelector:NULL
                       contextInfo:NULL];
}

@end
