@interface CRALogController : UIViewController <UIGestureRecognizerDelegate>
{
    UIWebView* webView;
    NSString* logMessage;
}
@property (nonatomic, retain) NSString* log;
-(id)initWithLog:(NSString*)logFile;
@end
