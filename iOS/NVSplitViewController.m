//  nvALT iOS — iPad split view root

#import "NVSplitViewController.h"
#import "NoteListViewController.h"
#import "NoteEditorViewController.h"

@implementation NVSplitViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.delegate = self;
    self.preferredDisplayMode = UISplitViewControllerDisplayModeOneBesideSecondary;
    self.presentsWithGesture = YES;

    NoteListViewController *listVC = [[NoteListViewController alloc] init];
    UINavigationController *primary = [[UINavigationController alloc] initWithRootViewController:listVC];
    primary.navigationBar.prefersLargeTitles = YES;

    // Detail column starts with a placeholder
    NoteEditorViewController *editorVC = [[NoteEditorViewController alloc] init];
    UINavigationController *detail = [[UINavigationController alloc] initWithRootViewController:editorVC];

    self.viewControllers = @[primary, detail];
}

#pragma mark - UISplitViewControllerDelegate

// On compact (iPhone) always show primary (list) when collapsing
- (BOOL)splitViewController:(UISplitViewController *)splitViewController
    collapseSecondaryViewController:(UIViewController *)secondaryViewController
    ontoPrimaryViewController:(UIViewController *)primaryViewController {
    // If the detail has no note, collapse to primary
    UINavigationController *detailNav = (UINavigationController *)secondaryViewController;
    NoteEditorViewController *editor = (NoteEditorViewController *)detailNav.topViewController;
    return (editor.note == nil);
}

@end
