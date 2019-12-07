@class Process;

@interface CRAProcViewController : UITableViewController <UIGestureRecognizerDelegate>
{
    Process* _proc;
}
-(instancetype)initWithProcess:(Process*)proc;
@end
