@class Process;

#define CR4ProcsNeedRefreshNotificationName @"com.muirey03.cr4shed-procsNeedRefresh"

@interface CRAProcViewController : UITableViewController <UIGestureRecognizerDelegate>
{
    Process* _proc;
}
-(instancetype)initWithProcess:(Process*)proc;
@end
