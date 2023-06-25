#import "CRASettingsViewController.h"
#import "UIImage+UIKitImage.h"
#import <sharedutils.h>
#import <Cephei/HBPreferences.h>
#import "CRABlacklistViewController.h"

void openURL(NSString* urlStr)
{
	NSURL* url = [NSURL URLWithString:urlStr];
	UIApplication* app = [UIApplication sharedApplication];
	[app openURL:url options:@{} completionHandler:nil];
}

@implementation CRASettingsViewController
+(instancetype)newSettingsController
{
	__block CRASettingsViewController* settingsVC = nil;

	//main section:
	FRPSection* mainSection = [FRPSection sectionWithTitle:@"General" footer:@""];
	FRPSegmentCell* segmentCell = [FRPSegmentCell
		cellWithTitle:@"Process sorting method"
		setting:[FRPSettings settingsWithKey:kSortingMethod defaultValue:@"Date"]
		values:@[@"Date", @"Name"]
		displayedValues:@[@"Date", @"Name"]
		postNotification:CR4ProcsNeedRefreshNotificationName
		changeBlock:^(NSString* value) {
			[settingsVC updatePrefsWithKey:kSortingMethod value:value];
		}
	];
	[mainSection addCell:segmentCell];
	[mainSection addCell:[FRPLinkCell cellWithTitle:@"Process blacklist" selectedBlock:^(id sender) {
		[settingsVC.navigationController pushViewController:[CRABlacklistViewController new] animated:YES];
	}]];
	FRPSwitchCell* jetsamCell = [FRPSwitchCell
		cellWithTitle:@"Log Jetsam Events"
		setting:[FRPSettings settingsWithKey:kEnableJetsam defaultValue:@YES]
		postNotification:CR4ProcsNeedRefreshNotificationName
		changeBlock:^(UISwitch* sender) {
			[settingsVC updatePrefsWithKey:kEnableJetsam value:@(sender.on)];
		}
	];
	[mainSection addCell:jetsamCell];

	//credits section
	FRPSection* creditsSection = [FRPSection sectionWithTitle:@"Credits" footer:@""];
	[creditsSection addCell:[FRPLinkCell cellWithTitle:@"Follow @Muirey03 on Twitter" selectedBlock:^(id sender) {
		openURL(@"https://twitter.com/Muirey03");
	}]];
	[creditsSection addCell:[FRPLinkCell cellWithTitle:@"Donate to help development" selectedBlock:^(id sender) {
		openURL(@"https://paypal.me/Muirey03Dev");
	}]];

	settingsVC = [CRASettingsViewController tableWithSections:@[mainSection, creditsSection] title:@"Settings" tintColor:nil];
	return settingsVC;
}

-(instancetype)initTableWithSections:(NSArray*)sections
{
	if ((self = [super initTableWithSections:sections]))
	{
		//initialise tabbar item:
		UIImage* itemImg = [[UIImage uikitImageNamed:@"BackgroundTask_settings"] resizeToWidth:25.];
		self.tabBarItem = [[UITabBarItem alloc] initWithTitle:self.title image:itemImg tag:0];
	}
	return self;
}

-(void)updatePrefsWithKey:(NSString*)key value:(id)value
{
	HBPreferences* prefs = sharedPreferences();
	[prefs setObject:value forKey:key];
#if THEOS_PACKAGE_SCHEME != rootless
	[prefs synchronize];
#endif
}

-(void)loadView
{
	[super loadView];
	if ([self.navigationController.navigationBar respondsToSelector:@selector(setPrefersLargeTitles:)])
		self.navigationController.navigationBar.prefersLargeTitles = YES;
}

-(void)viewDidAppear:(BOOL)arg1
{
	[super viewDidAppear:arg1];
	self.navigationController.interactivePopGestureRecognizer.delegate = nil;
	self.navigationController.interactivePopGestureRecognizer.enabled = NO;
}
@end
