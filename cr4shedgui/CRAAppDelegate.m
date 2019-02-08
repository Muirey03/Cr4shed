#import "CRAAppDelegate.h"
#import "CRARootViewController.h"

@implementation CRAAppDelegate

-(void)applicationDidFinishLaunching:(UIApplication*)application
{
	_window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	_rootViewController = [[UINavigationController alloc] initWithRootViewController:[[CRARootViewController alloc] init]];
	_window.rootViewController = _rootViewController;
	[_window makeKeyAndVisible];
}

@end
