@class Process;
@interface CRAProcViewController : UITableViewController <UIGestureRecognizerDelegate>
@property (nonatomic, strong) Process* proc;
-(instancetype)initWithProcess:(Process*)proc;
@end
