//  nvALT iOS — note storage and filtering

#import "NVNotesManager.h"
#import "NVNote.h"

NSString *const NVNotesManagerDidChangeNotification = @"NVNotesManagerDidChangeNotification";

@interface NVNotesManager ()
@property (nonatomic, strong) NSMutableArray<NVNote *> *allNotes;
@end

@implementation NVNotesManager

+ (instancetype)sharedManager {
    static NVNotesManager *shared;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ shared = [[NVNotesManager alloc] init]; });
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _allNotes = [NSMutableArray array];
        _searchString = @"";
    }
    return self;
}

#pragma mark - Persistence

- (NSString *)storagePath {
    NSString *docs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    return [docs stringByAppendingPathComponent:@"nvalt_notes.json"];
}

- (void)loadNotes {
    NSData *data = [NSData dataWithContentsOfFile:[self storagePath]];
    if (data) {
        NSArray *dicts = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if ([dicts isKindOfClass:[NSArray class]]) {
            NSMutableArray *loaded = [NSMutableArray arrayWithCapacity:dicts.count];
            for (NSDictionary *d in dicts) {
                NVNote *n = [[NVNote alloc] initWithDictionary:d];
                [loaded addObject:n];
            }
            _allNotes = loaded;
        }
    }
    [self postChange];
}

- (void)saveNotes {
    NSMutableArray *dicts = [NSMutableArray arrayWithCapacity:_allNotes.count];
    for (NVNote *n in _allNotes) {
        [dicts addObject:[n toDictionary]];
    }
    NSData *data = [NSJSONSerialization dataWithJSONObject:dicts options:NSJSONWritingPrettyPrinted error:nil];
    [data writeToFile:[self storagePath] atomically:YES];
}

#pragma mark - Filtered notes

- (void)setSearchString:(NSString *)searchString {
    _searchString = searchString ?: @"";
    [self postChange];
}

- (NSArray<NVNote *> *)filteredNotes {
    NSArray *source = _allNotes;
    if (_searchString.length > 0) {
        NSPredicate *p = [NSPredicate predicateWithFormat:
            @"title CONTAINS[cd] %@ OR content CONTAINS[cd] %@ OR tags CONTAINS[cd] %@",
            _searchString, _searchString, _searchString];
        source = [source filteredArrayUsingPredicate:p];
    }
    return [source sortedArrayUsingDescriptors:@[
        [NSSortDescriptor sortDescriptorWithKey:@"modifiedDate" ascending:NO]
    ]];
}

#pragma mark - CRUD

- (NVNote *)createNoteWithTitle:(NSString *)title content:(NSString *)content {
    NVNote *note = [[NVNote alloc] initWithTitle:title content:content];
    [_allNotes addObject:note];
    [self saveNotes];
    [self postChange];
    return note;
}

- (void)deleteNote:(NVNote *)note {
    [_allNotes removeObject:note];
    [self saveNotes];
    [self postChange];
}

- (void)updateNote:(NVNote *)note title:(NSString *)title content:(NSString *)content {
    note.title = title;
    note.content = content;
    note.modifiedDate = [NSDate date];
    [self saveNotes];
    [self postChange];
}

#pragma mark - Private

- (void)postChange {
    [[NSNotificationCenter defaultCenter] postNotificationName:NVNotesManagerDidChangeNotification object:self];
}

@end
