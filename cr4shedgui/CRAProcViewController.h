@class Process;

@interface CRAProcViewController : UITableViewController <UIGestureRecognizerDelegate>
{
    Process* _proc;
}
-(id)initWithProcess:(Process*)arg1;
@end
