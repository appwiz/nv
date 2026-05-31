//  nvALT iOS — application delegate

#import "AppDelegate_iOS.h"
#import "NVNotesManager.h"
#import "NoteListViewController.h"
#import "NVSplitViewController.h"

@implementation AppDelegate_iOS

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Scene-based lifecycle handles window setup on iOS 13+; this runs only on older iOS.
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [[NVNotesManager sharedManager] saveNotes];
}

@end
