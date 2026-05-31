//  nvALT iOS — note data model

#import <Foundation/Foundation.h>

@interface NVNote : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *content;
@property (nonatomic, copy) NSString *tags;
@property (nonatomic, strong) NSDate *modifiedDate;
@property (nonatomic, strong) NSDate *createdDate;
@property (nonatomic, copy) NSString *uniqueID;

- (instancetype)initWithTitle:(NSString *)title content:(NSString *)content;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)toDictionary;

- (NSString *)titlePreview;
- (NSString *)contentPreview;

@end
