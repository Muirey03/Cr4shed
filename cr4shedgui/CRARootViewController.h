@class Process;
@class CRAProcessManager;

@interface ProcessCell : UITableViewCell
{
	UILabel* _countLbl;
	NSLayoutConstraint* _widthConstraint;
	NSLayoutConstraint* _heightConstraint;
}
@property (nonatomic, strong) Process* proc;
-(void)updateLabels;
@end

@interface CRARootViewController : UITableViewController
{
	UIRefreshControl* _refreshControl;
	CRAProcessManager* _processManager;
	NSMutableArray<Process*>* _procs;
}
-(void)refreshTable:(UIRefreshControl*)control;
-(void)deleteProcessAtIndexPath:(NSIndexPath*)indexPath;
@end

@interface UIColor (System)
@property(class, nonatomic, readonly) UIColor* systemRedColor;
@property(class, nonatomic, readonly) UIColor* systemBlueColor;
@end