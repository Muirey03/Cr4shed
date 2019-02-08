@interface CRALogController : UIViewController <UIGestureRecognizerDelegate>
{
    UITextView* textView;
    NSString* logMessage;
}
@property (nonatomic, retain) NSString* log;
-(id)initWithLog:(NSString*)logFile;
@end
