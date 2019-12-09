@import UserNotifications;

@interface CRAAppDelegate : UIResponder <UIApplicationDelegate, UNUserNotificationCenterDelegate>
{
	UITabBarController* _tabBarVC;
	UINavigationController* _rootViewController;
	UINavigationController* _settingsViewController;
}
@property (nonatomic, retain) UIWindow* window;
@end
