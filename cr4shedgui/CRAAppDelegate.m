#import "CRAAppDelegate.h"
#import "CRARootViewController.h"
#import "CRASettingsViewController.h"
#import "CRALogController.h"
#import "Log.h"

@implementation CRAAppDelegate

-(BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
	[UNUserNotificationCenter currentNotificationCenter].delegate = self;

	//create UI:
	_window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	
	_rootViewController = [[UINavigationController alloc] initWithRootViewController:[CRARootViewController new]];
	_settingsViewController = [[UINavigationController alloc] initWithRootViewController:[CRASettingsViewController newSettingsController]];

	_tabBarVC = [UITabBarController new];
	_tabBarVC.viewControllers = @[_rootViewController, _settingsViewController];
	_window.rootViewController = _tabBarVC;
	[_window makeKeyAndVisible];
	return YES;
}

-(void)applicationDidBecomeActive:(UIApplication*)application
{
	//reset badge number:
	[application setApplicationIconBadgeNumber:0];
}

-(void)userNotificationCenter:(UNUserNotificationCenter*)center didReceiveNotificationResponse:(UNNotificationResponse*)response withCompletionHandler:(void (^)(void))completionHandler
{
	NSString* logPath = response.notification.request.content.userInfo[@"logPath"];
	if (logPath.length)
		[self displayLog:logPath];
	if (completionHandler)
		completionHandler();
}

-(void)displayLog:(NSString*)logPath
{
	Log* log = [[Log alloc] initWithPath:logPath];
	CRALogController* logVC = [[CRALogController alloc] initWithLog:log];
	_tabBarVC.selectedViewController = _rootViewController;
	[_rootViewController pushViewController:logVC animated:YES];
}

@end
