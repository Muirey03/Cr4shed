@class Process;

@interface ProcessCell : UITableViewCell
{
    UILabel* _countLbl;
    NSLayoutConstraint* _widthConstraint;
    NSLayoutConstraint* _heightConstraint;
}
@property (nonatomic, retain) Process* proc;
-(void)updateLabels;
@end

@interface CRARootViewController : UITableViewController
{
	UIRefreshControl* _refreshControl;
}
-(void)refreshTable:(UIRefreshControl*)control;
-(void)sortProcs;
-(void)loadLogs;
@end

@interface UIColor (System)
@property(class, nonatomic, readonly) UIColor* systemRedColor;
@end