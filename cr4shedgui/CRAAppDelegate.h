@import UserNotifications;

@interface CRAAppDelegate : UIResponder <UIApplicationDelegate, UNUserNotificationCenterDelegate>
@property (nonatomic, retain) UIWindow* window;
@property (nonatomic, retain) UINavigationController* rootViewController;
@end
