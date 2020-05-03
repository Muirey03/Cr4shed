#import "CRAProcessManager.h"
#import "Process.h"
#import "Log.h"
#import <sharedutils.h>

@implementation CRAProcessManager
+(instancetype)sharedInstance
{
	static CRAProcessManager* instance = nil;
	static dispatch_once_t onceToken = 0;
	dispatch_once (&onceToken, ^{
		instance = [CRAProcessManager new];
	});
	return instance;
}

-(instancetype)init
{
	if ((self = [super init]))
	{
		[self refresh];
	}
	return self;
}

-(void)refresh
{
	_processes = [NSMutableArray new];
	//loop through all logs
	NSString* const logsDirectory = @"/var/mobile/Library/Cr4shed";
	NSMutableArray* files = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:logsDirectory error:nil] mutableCopy];
	for (int i = 0; i < files.count; i++)
	{
		NSString* fileName = files[i];
		NSString* filePath = [logsDirectory stringByAppendingPathComponent:fileName];
		if (![[fileName pathExtension] isEqualToString:@"log"])
		{
			[files removeObjectAtIndex:i];
			i--;
			continue;
		}
		//file is a log
		Process* proc = nil;
		NSArray<NSString*>* comp = [fileName componentsSeparatedByString:@"@"];
		NSString* procName = comp.count > 1 ? comp[0] : @"(null)";

		//check if process is already in array
		for (Process* p in _processes)
		{
			if ([p.name isEqualToString:procName])
			{
				proc = p;
				break;
			}
		}
		if (!proc)
		{
			//process isn't in array, add it
			proc = [[Process alloc] initWithName:procName];
			[_processes addObject:proc];
		}
		Log* log = [[Log alloc] initWithPath:filePath];
		[proc.logs addObject:log];

		NSDate* date = log.date;
		if (!proc.latestDate || [proc.latestDate compare:date] == NSOrderedAscending)
		{
			proc.latestDate = date;
		}
	}

	[self sortProcs];
}

-(void)sortProcs
{
	NSString* sortingMethod = [[NSUserDefaults standardUserDefaults] objectForKey:kSortingMethod];
	[_processes sortUsingComparator:^NSComparisonResult(Process* a, Process* b) {
		/*
		Sorting method:
		Date = @"Date" or nil
		Name = @"Name"
		*/
		if ([sortingMethod isEqualToString:@"Name"])
			return [[a.name lowercaseString] compare:[b.name lowercaseString]];
		NSDate* first = a.latestDate;
		NSDate* second = b.latestDate; 
		return [second compare:first];
	}];
	for (int i = 0; i < _processes.count; i++)
	{
		if (_processes[i].logs.count == 0)
		{
			[_processes removeObjectAtIndex:i];
			i--;
		}
	}
}
@end
