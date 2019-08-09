#import "CRAAppDelegate.h"
#import "CRARootViewController.h"
#import "CRALogController.h"

@implementation CRAAppDelegate

-(BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
	//create UI:
	_window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	_rootViewController = [[UINavigationController alloc] initWithRootViewController:[[CRARootViewController alloc] init]];
	_window.rootViewController = _rootViewController;
	[_window makeKeyAndVisible];

	//open crash log if app was opened via a notification
	UILocalNotification* notif = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
	if (notif)
	{
		NSString* logPath = notif.userInfo[@"logPath"];
		[self displayLog:logPath];
	}

	//reset badge number:
	[application setApplicationIconBadgeNumber:0];
	return YES;
}

-(void)displayLog:(NSString*)logPath
{
	NSString* log = [logPath lastPathComponent];
	CRALogController* logVC = [[CRALogController alloc] initWithLog:log];
	[_rootViewController pushViewController:logVC animated:YES];
}

@end
