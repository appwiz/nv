//  nvALT iOS — note editor

#import <UIKit/UIKit.h>

@class NVNote;

@interface NoteEditorViewController : UIViewController <UITextViewDelegate>
@property (nonatomic, strong) NVNote *note;
@end
