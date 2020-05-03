#import "Log.h"
#import <sharedutils.h>

@implementation Log
{
	NSString* _contents;
	NSDictionary* _info;
}

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

-(NSString*)dateName
{
	NSArray<NSString*>* comp = [[_path lastPathComponent] componentsSeparatedByString:@"@"];
	return comp.count > 1 ? comp[1] : comp[0];
}

-(NSString*)processName
{
	NSDictionary* info = self.info;
	if (info[@"ProcessName"])
		return info[@"ProcessName"];
	NSArray<NSString*>* comp = [[_path lastPathComponent] componentsSeparatedByString:@"@"];
	return comp.count ? comp[0] : nil;
}

-(NSString*)contents
{
	if (!_contents)
		_contents = [NSString stringWithContentsOfFile:_path encoding:NSUTF8StringEncoding error:NULL];
	return _contents;
}

-(NSDictionary*)info
{
	if (!_info)
		_info = getInfoFromLog(self.contents);
	return _info;
}
@end