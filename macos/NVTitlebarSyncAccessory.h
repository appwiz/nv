//
//  NVTitlebarSyncAccessory.h
//  Notation
//
//  AppKit-native replacement for TitlebarButton. Hosts a small sync-status
//  indicator in the window's title bar via NSTitlebarAccessoryViewController.
//

#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSInteger, NVTitlebarSyncIconType) {
    NVTitlebarSyncIconNone,           // accessory hidden
    NVTitlebarSyncIconChevron,        // pulls-down menu trigger
    NVTitlebarSyncIconSynchronizing,  // indeterminate spinner
    NVTitlebarSyncIconAlert,          // error / warning state
};

@interface NVTitlebarSyncAccessory : NSTitlebarAccessoryViewController

// Menu shown when the user clicks the chevron icon. Set to the sync-status
// menu provided by SyncSessionController. Property is named with the nv_
// prefix to avoid colliding with NSResponder's own `menu` property.
@property (nonatomic, retain) NSMenu *nv_menu;

- (void)setIconType:(NVTitlebarSyncIconType)type;

@end
