#import "Process.h"
#import "Log.h"
#import <Cephei/HBPreferences.h>
#import <sharedutils.h>

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

-(void)addToBlacklist
{
	HBPreferences* prefs = sharedPreferences();
	NSArray<NSString*>* blacklist = [prefs objectForKey:kProcessBlacklist];
	NSMutableSet<NSString*>* blacklistSet = blacklist ? [NSMutableSet setWithArray:blacklist] : [NSMutableSet new];
	[blacklistSet addObject:_name];
	[prefs setObject:[blacklistSet allObjects] forKey:kProcessBlacklist];
}

-(void)removeFromBlacklist
{
	HBPreferences* prefs = sharedPreferences();
	NSMutableArray<NSString*>* blacklist = [[prefs objectForKey:kProcessBlacklist] mutableCopy];
	if (blacklist.count)
	{
		[blacklist removeObject:_name];
		[prefs setObject:[blacklist copy] forKey:kProcessBlacklist];
	}
}

-(BOOL)isBlacklisted
{
	HBPreferences* prefs = sharedPreferences();
	NSArray<NSString*>* blacklist = [prefs objectForKey:kProcessBlacklist];
	return [blacklist containsObject:_name];
}

-(void)deleteAllLogs
{
	for (Log* log in _logs)
		[[NSFileManager defaultManager] removeItemAtPath:log.path error:NULL];
	_logs = [NSMutableArray new];
}
@end
