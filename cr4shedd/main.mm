@import CoreFoundation;
@import Foundation;

#import <MRYIPCCenter.h>
#import <sharedutils.h>
#import <pthread.h>
#import <time.h>
#import <rootless.h>

@interface Cr4shedServer : NSObject
-(BOOL)createDirectoryAtPath:(NSString*)path;
@end

@implementation Cr4shedServer
{
	MRYIPCCenter* _ipcCenter;
}

+(void)load
{
	[self sharedInstance];
}

+(id)sharedInstance
{
	static dispatch_once_t once = 0;
	__strong static id sharedInstance = nil;
	dispatch_once(&once, ^{
		sharedInstance = [[self alloc] init];
	});
	return sharedInstance;
}

-(id)init
{
	if ((self = [super init]))
	{
		_ipcCenter = [MRYIPCCenter centerNamed:@"com.muirey03.cr4sheddserver"];
		[_ipcCenter addTarget:self action:@selector(writeString:)];
		[_ipcCenter addTarget:self action:@selector(sendNotification:)];
		[_ipcCenter addTarget:self action:@selector(stringFromTime:)];
		[_ipcCenter addTarget:self action:@selector(isProcessBlacklisted:)];
	}
	return self;
}

-(NSDictionary*)writeString:(NSDictionary*)userInfo
{
	//get info from userInfo:
	NSString* str = userInfo[@"string"];
	NSString* filename = [userInfo[@"filename"] lastPathComponent];
	if (!filename)
		return nil;
	NSString* fullFilename = [filename stringByAppendingPathExtension:@"log"];
	//validate filename is safe:
	if ([fullFilename pathComponents].count > 1)
		return nil;
	//formulate path:
	NSString* const cr4Dir = ROOT_PATH_NS_VAR(@"/var/mobile/Library/Cr4shed");
	NSString* path = [cr4Dir stringByAppendingPathComponent:fullFilename];
	//create cr4shed dir if neccessary:
	//(deleting it if it is a file not a dir)
	NSFileManager* manager = [NSFileManager defaultManager];
	BOOL isDir = NO;
	BOOL exists = [manager fileExistsAtPath:cr4Dir isDirectory:&isDir];
	if (!exists || !isDir)
	{
		if (exists)
			[manager removeItemAtPath:cr4Dir error:NULL];
		exists = [self createDirectoryAtPath:cr4Dir];
		if (!exists)
			return nil;
	}
	//change path so that it doesn't conflict:
	for (unsigned long long i = 1; [[NSFileManager defaultManager] fileExistsAtPath:path]; i++)
		path = [cr4Dir stringByAppendingPathComponent:[[NSString stringWithFormat:@"%@ (%llu)", filename, i] stringByAppendingPathExtension:@"log"]];
	//create new file:
	NSDictionary<NSFileAttributeKey, id>* attributes = @{
		NSFilePosixPermissions : @0666,
		NSFileOwnerAccountName : @"mobile",
		NSFileGroupOwnerAccountName : @"mobile"
	};
	NSData* contentsData = [str dataUsingEncoding:NSUTF8StringEncoding];
	[manager createFileAtPath:path contents:contentsData attributes:attributes];
	return @{@"path" : path};
}

-(BOOL)createDirectoryAtPath:(NSString*)path
{
	NSDictionary<NSFileAttributeKey, id>* attributes = @{
		NSFilePosixPermissions : @0755,
		NSFileOwnerAccountName : @"mobile",
		NSFileGroupOwnerAccountName : @"mobile"
	};
	return [[NSFileManager defaultManager] createDirectoryAtURL:[NSURL fileURLWithPath:path] withIntermediateDirectories:YES attributes:attributes error:NULL];
}

-(void)sendNotification:(NSDictionary*)userInfo
{
	NSString* content = userInfo[@"content"];
	NSDictionary* notifUserInfo = userInfo[@"userInfo"];
	showCr4shedNotification(content, notifUserInfo);
}

-(NSDictionary*)stringFromTime:(NSDictionary*)userInfo
{
	time_t t = (time_t)[userInfo[@"time"] integerValue];
	CR4DateFormat type = (CR4DateFormat)[userInfo[@"type"] integerValue];
	NSDate* date = [NSDate dateWithTimeIntervalSince1970:t];
	NSString* ret = stringFromDate(date, type);
	return ret ? @{@"ret" : ret} : @{};
}

-(NSNumber*)isProcessBlacklisted:(NSString*)procName
{
	return @(isBlacklisted(procName));
}

-(NSNumber*)shouldLogJetsam {
	return @(wantsLogJetsam());
}
@end

int main(int argc, char** argv, char** envp)
{
	@autoreleasepool
	{
		[Cr4shedServer load];

		NSRunLoop* runLoop = [NSRunLoop currentRunLoop];
		for (;;)
			[runLoop run];
		return 0;
	}
}
