#import "Process.h"

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
@end
