@class Process;
@class CRAProcessManager;

@interface CRAProcViewController : UITableViewController <UIGestureRecognizerDelegate>
{
	UIRefreshControl* _refreshControl;
	CRAProcessManager* _processManager;
}
@property (nonatomic, strong) Process* proc;
-(instancetype)initWithProcess:(Process*)proc;
-(void)refreshLogs;
@end
