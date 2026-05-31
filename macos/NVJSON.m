//
//  NVJSON.m
//  Notation
//

#import "NVJSON.h"

@implementation NSDictionary (NVJSON)

- (NSData *)nv_jsonData {
    if (![NSJSONSerialization isValidJSONObject:self]) return nil;
    return [NSJSONSerialization dataWithJSONObject:self options:0 error:NULL];
}

- (NSString *)nv_jsonString {
    NSData *data = [self nv_jsonData];
    if (!data) return nil;
    return [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
}

@end

@implementation NSArray (NVJSON)

- (NSData *)nv_jsonData {
    if (![NSJSONSerialization isValidJSONObject:self]) return nil;
    return [NSJSONSerialization dataWithJSONObject:self options:0 error:NULL];
}

@end

NSDictionary *NVDictionaryFromJSONString(NSString *s) {
    if (!s) return nil;
    NSData *data = [s dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) return nil;
    id parsed = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
    if (![parsed isKindOfClass:[NSDictionary class]]) return nil;
    return parsed;
}
