@class Process;

@interface ProcessCell : UITableViewCell
@property (nonatomic, retain) Process* proc;
@property (nonatomic, retain) UILabel* countLbl;
@end

@interface CRARootViewController : UITableViewController
-(void)sortProcs;
-(void)loadLogs;
@end
