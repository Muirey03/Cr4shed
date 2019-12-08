#import "CRAAppDelegate.h"
#import "CRARootViewController.h"
#import "CRALogController.h"
#import "Log.h"

@implementation CRAAppDelegate

-(BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
	[UNUserNotificationCenter currentNotificationCenter].delegate = self;

	//create UI:
	_window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	_rootViewController = [[UINavigationController alloc] initWithRootViewController:[[CRARootViewController alloc] init]];
	_window.rootViewController = _rootViewController;
	[_window makeKeyAndVisible];

	//reset badge number:
	[application setApplicationIconBadgeNumber:0];
	return YES;
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
	[_rootViewController pushViewController:logVC animated:YES];
}

@end
