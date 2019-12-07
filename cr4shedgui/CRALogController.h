@import WebKit;

@class Log;
@interface CRALogController : UIViewController <UIGestureRecognizerDelegate>
{
    WKWebView* webView;
    NSString* logMessage;
}
@property (nonatomic, retain) Log* log;
-(instancetype)initWithLog:(Log*)log;
@end
