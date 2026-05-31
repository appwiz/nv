//  nvALT iOS — note list (iPhone/iPad primary column)

#import <UIKit/UIKit.h>

@class NVNote;

@interface NoteListViewController : UIViewController
                                    <UITableViewDataSource,
                                     UITableViewDelegate,
                                     UISearchResultsUpdating,
                                     UISearchBarDelegate>

- (void)openNote:(NVNote *)note animated:(BOOL)animated;

@end
