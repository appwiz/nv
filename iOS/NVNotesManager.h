//  nvALT iOS — note storage and filtering

#import <Foundation/Foundation.h>

@class NVNote;

extern NSString *const NVNotesManagerDidChangeNotification;

@interface NVNotesManager : NSObject

@property (nonatomic, readonly) NSArray<NVNote *> *filteredNotes;
@property (nonatomic, copy) NSString *searchString;

+ (instancetype)sharedManager;

- (void)loadNotes;
- (void)saveNotes;

- (NVNote *)createNoteWithTitle:(NSString *)title content:(NSString *)content;
- (void)deleteNote:(NVNote *)note;
- (void)updateNote:(NVNote *)note title:(NSString *)title content:(NSString *)content;

@end
