#import "Process.h"
#import "Log.h"

@implementation Process
-(instancetype)initWithName:(NSString*)procName
{
	if ((self = [self init]))
	{
		_name = procName;
		_logs = [NSMutableArray new];
	}
	return self;
}

-(void)deleteAllLogs
{
	for (Log* log in _logs)
		[[NSFileManager defaultManager] removeItemAtPath:log.path error:NULL];
	_logs = [NSMutableArray new];
}
@end
