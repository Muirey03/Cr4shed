@import WebKit;
@interface CRALogController : UIViewController <UIGestureRecognizerDelegate>
{
    WKWebView* webView;
    NSString* logMessage;
}
@property (nonatomic, retain) NSString* log;
-(id)initWithLog:(NSString*)logFile;
@end
