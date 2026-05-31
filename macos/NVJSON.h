//
//  NVJSON.h
//  Notation
//
//  Thin Foundation-backed helpers used by the Simplenote sync path. Replaces
//  the vendored BSJSONAdditions library with NSJSONSerialization (10.7+).
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (NVJSON)
- (nullable NSData *)nv_jsonData;
- (nullable NSString *)nv_jsonString;
@end

@interface NSArray (NVJSON)
- (nullable NSData *)nv_jsonData;
@end

// Returns nil on malformed JSON or on a non-dictionary top-level value.
NSDictionary * _Nullable NVDictionaryFromJSONString(NSString * _Nullable s);

NS_ASSUME_NONNULL_END
