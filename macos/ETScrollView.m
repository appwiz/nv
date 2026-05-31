//
//  ETScrollView.m
//  Notation
//

#import "ETScrollView.h"

@implementation ETScrollView

+ (BOOL)isCompatibleWithResponsiveScrolling {
    return NO;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    if ([self.documentView isKindOfClass:[NSTableView class]]) {
        [self setAutohidesScrollers:YES];
    }
    [self setHorizontalScrollElasticity:NSScrollElasticityNone];
    [self setVerticalScrollElasticity:NSScrollElasticityAllowed];
}

@end
