#import "Log.h"

@implementation Log
-(instancetype)initWithPath:(NSString*)path
{
	if ((self = [self init]))
	{
		_path = path;

		//get date:
		NSDictionary* fileAttribs = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
		_date = [fileAttribs objectForKey:NSFileCreationDate];
	}
	return self;
}
@end