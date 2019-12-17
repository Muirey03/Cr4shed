@class Log;

@interface Process : NSObject
@property (nonatomic, strong) NSString* name;
@property (nonatomic, strong) NSDate* latestDate;
@property (nonatomic, strong) NSMutableArray<Log*>* logs;
-(instancetype)initWithName:(NSString*)procName;
-(void)deleteAllLogs;
-(void)addToBlacklist;
-(void)removeFromBlacklist;
-(BOOL)isBlacklisted;
@end
