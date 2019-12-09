#import "CRASettingsViewController.h"
#import "UIImage+UIKitImage.h"
#import "../sharedutils.h"

@implementation CRASettingsViewController
+(instancetype)newSettingsController
{
	FRPSection* section1 = [FRPSection sectionWithTitle:@"General" footer:@""];
	FRPSegmentCell* segmentCell = [FRPSegmentCell   cellWithTitle:@"Process sorting method"
                                                	setting:[FRPSettings settingsWithKey:@"SortingMethod" defaultValue:@"Date"]
                                                    values:@[@"Date", @"Name"]
                                            		displayedValues:@[@"Date", @"Name"]
                                           			postNotification:CR4ProcsNeedRefreshNotificationName
                                                	changeBlock:^(NSString* item) {}];
	[section1 addCell:segmentCell];
	return [CRASettingsViewController tableWithSections:@[section1] title:@"Settings" tintColor:nil];
}

-(instancetype)initTableWithSections:(NSArray*)sections
{
	if ((self = [super initTableWithSections:sections]))
	{
		UIImage* itemImg = [[UIImage uikitImageNamed:@"BackgroundTask_settings"] resizeToWidth:25.];
		self.tabBarItem = [[UITabBarItem alloc] initWithTitle:self.title image:itemImg tag:0];
	}
	return self;
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