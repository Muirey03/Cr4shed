@class Process;

@interface CRAProcessManager : NSObject
@property (nonatomic, strong) NSMutableArray<Process*>* processes;
+(instancetype)sharedInstance;
-(void)refresh;
-(void)sortProcs;
@end
