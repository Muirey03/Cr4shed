@class Process;

@interface ProcessCell : UITableViewCell
@property (nonatomic, retain) Process* proc;
@property (nonatomic, retain) UILabel* countLbl;
@end

@interface CRARootViewController : UITableViewController
{
	UIRefreshControl* _refreshControl;
}
-(void)refreshTable:(UIRefreshControl*)control;
-(void)sortProcs;
-(void)loadLogs;
@end

@interface UITableView (iOS10)
-(void)setRefreshControl:(id)arg1;
@end
