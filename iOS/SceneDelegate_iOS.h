//  nvALT iOS — scene delegate (iOS 13+)

#import <UIKit/UIKit.h>

API_AVAILABLE(ios(13.0))
@interface SceneDelegate_iOS : UIResponder <UIWindowSceneDelegate>
@property (strong, nonatomic) UIWindow *window;
@end
