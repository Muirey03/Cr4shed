@import MessageUI;
@class Log;

@interface UIImage (Internal)
+(UIImage*)_applicationIconImageForBundleIdentifier:(NSString*)bundleID format:(int)format scale:(CGFloat)scale;
@end

@interface CRALogInfoViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate, MFMailComposeViewControllerDelegate>
{
	NSDictionary* _info;
}
@property (nonatomic, readonly) UITableView* tableView;
@property (nonatomic, strong) Log* log;
-(instancetype)initWithLog:(Log*)log;
-(void)displayErrorAlert:(NSString*)body;
-(void)composeEmail;
@end

@interface UIColor (System)
@property(class, nonatomic, readonly) UIColor* systemRedColor;
@property(class, nonatomic, readonly) UIColor* systemBlueColor;
@end