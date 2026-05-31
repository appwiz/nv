//  nvALT iOS — scene delegate (iOS 13+)

#import "SceneDelegate_iOS.h"
#import "NVNotesManager.h"
#import "NoteListViewController.h"
#import "NVSplitViewController.h"

@implementation SceneDelegate_iOS

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session
      options:(UISceneConnectionOptions *)connectionOptions API_AVAILABLE(ios(13.0)) {
    UIWindowScene *windowScene = (UIWindowScene *)scene;
    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];

    [[NVNotesManager sharedManager] loadNotes];

    UIViewController *rootVC;
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        rootVC = [[NVSplitViewController alloc] init];
    } else {
        NoteListViewController *listVC = [[NoteListViewController alloc] init];
        rootVC = [[UINavigationController alloc] initWithRootViewController:listVC];
    }

    self.window.rootViewController = rootVC;
    [self.window makeKeyAndVisible];
}

- (void)sceneDidEnterBackground:(UIScene *)scene API_AVAILABLE(ios(13.0)) {
    [[NVNotesManager sharedManager] saveNotes];
}

@end
