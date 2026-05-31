//  nvALT iOS — note data model

#import "NVNote.h"

@implementation NVNote

- (instancetype)initWithTitle:(NSString *)title content:(NSString *)content {
    self = [super init];
    if (self) {
        _title = title ?: @"";
        _content = content ?: @"";
        _tags = @"";
        _modifiedDate = [NSDate date];
        _createdDate = [NSDate date];
        _uniqueID = [[NSUUID UUID] UUIDString];
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _title = dict[@"title"] ?: @"";
        _content = dict[@"content"] ?: @"";
        _tags = dict[@"tags"] ?: @"";
        _uniqueID = dict[@"uniqueID"] ?: [[NSUUID UUID] UUIDString];

        double modTime = [dict[@"modifiedDate"] doubleValue];
        double createTime = [dict[@"createdDate"] doubleValue];
        _modifiedDate = modTime > 0 ? [NSDate dateWithTimeIntervalSinceReferenceDate:modTime] : [NSDate date];
        _createdDate  = createTime > 0 ? [NSDate dateWithTimeIntervalSinceReferenceDate:createTime] : [NSDate date];
    }
    return self;
}

- (NSDictionary *)toDictionary {
    return @{
        @"title":        _title ?: @"",
        @"content":      _content ?: @"",
        @"tags":         _tags ?: @"",
        @"uniqueID":     _uniqueID ?: [[NSUUID UUID] UUIDString],
        @"modifiedDate": @([_modifiedDate timeIntervalSinceReferenceDate]),
        @"createdDate":  @([_createdDate timeIntervalSinceReferenceDate]),
    };
}

- (NSString *)titlePreview {
    NSString *t = [_title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return t.length > 0 ? t : @"Untitled";
}

- (NSString *)contentPreview {
    NSString *stripped = [_content stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (stripped.length > 120) {
        stripped = [stripped substringToIndex:120];
    }
    return stripped;
}

@end
