@import WebKit;

@class Log;
@interface CRALogController : UIViewController <UIGestureRecognizerDelegate>
{
	WKWebView* webView;
	NSString* logMessage;
}
@property (nonatomic, strong) Log* log;
-(instancetype)initWithLog:(Log*)log;
@end
