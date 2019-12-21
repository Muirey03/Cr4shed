#include "../AppSupport/CPDistributedMessagingCenter.h"
#import "../rocketbootstrap/rocketbootstrap.h"
#import "../libnotifications.h"
#import "../sharedutils.h"
#include <pthread.h>
#include <time.h>

@interface Cr4shedServer : NSObject
@end

@implementation Cr4shedServer

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
        CPDistributedMessagingCenter* messagingCenter = [CPDistributedMessagingCenter centerNamed:@"com.muirey03.Cr4shedServer"];
        rocketbootstrap_distributedmessagingcenter_apply(messagingCenter);
        [messagingCenter runServerOnCurrentThread];

		[messagingCenter registerForMessageName:@"writeString" target:self selector:@selector(writeString:withUserInfo:)];
		[messagingCenter registerForMessageName:@"createDir" target:self selector:@selector(createDir:withUserInfo:)];
	    [messagingCenter registerForMessageName:@"sendNotification" target:self selector:@selector(sendNotification:withUserInfo:)];
        [messagingCenter registerForMessageName:@"stringFromTime" target:self selector:@selector(stringFromTime:withUserInfo:)];
    }
    return self;
}

-(NSDictionary*)writeString:(NSString*)name withUserInfo:(NSDictionary*)userInfo
{
    NSString* str = userInfo[@"string"];
    NSString* path = userInfo[@"path"];
    NSFileManager* manager = [NSFileManager defaultManager];
	if ([manager fileExistsAtPath:path])
		[manager removeItemAtPath:path error:NULL];
	NSDictionary<NSFileAttributeKey, id>* attributes = @{
		NSFilePosixPermissions : @0666,
        NSFileOwnerAccountName : @"mobile",
        NSFileGroupOwnerAccountName : @"mobile"
	};
	NSData* contentsData = [str dataUsingEncoding:NSUTF8StringEncoding];
	[manager createFileAtPath:path contents:contentsData attributes:attributes];
    return nil;
}

-(NSDictionary*)createDir:(NSString*)name withUserInfo:(NSDictionary*)userInfo
{
    NSString* path = userInfo[@"path"];
    NSDictionary<NSFileAttributeKey, id>* attributes = @{
		NSFilePosixPermissions : @0755,
        NSFileOwnerAccountName : @"mobile",
        NSFileGroupOwnerAccountName : @"mobile"
	};
    BOOL success = [[NSFileManager defaultManager] createDirectoryAtURL:[NSURL fileURLWithPath:path] withIntermediateDirectories:YES attributes:attributes error:nil];
    return @{@"success" : @(success)};
}

-(NSDictionary*)sendNotification:(NSString*)name withUserInfo:(NSDictionary*)userInfo
{
    NSString* content = userInfo[@"content"];
	NSString* bundleID = @"com.muirey03.cr4shedgui";
	NSString* title = @"Cr4shed";
    NSDictionary* notifUserInfo = userInfo[@"userInfo"];
    [CPNotification showAlertWithTitle:title
                                message:content
                                userInfo:notifUserInfo
                                badgeCount:1
                                soundName:nil
                                delay:0.
                                repeats:NO
                                bundleId:bundleID];
    return nil;
}

-(NSDictionary*)stringFromTime:(NSString*)name withUserInfo:(NSDictionary*)userInfo
{
    time_t t = (time_t)[userInfo[@"time"] integerValue];
    CR4DateFormat type = (CR4DateFormat)[userInfo[@"type"] integerValue];
    NSDate* date = [NSDate dateWithTimeIntervalSince1970:t];
    NSString* ret = stringFromDate(date, type);
    return ret ? @{@"ret" : ret} : @{};
}
@end

%ctor
{
    [Cr4shedServer load];
}

#pragma mark Testing
#if 0
@interface SpringBoard
-(void)crash;
@end

void test(void) {}

%hook SpringBoard
-(void)applicationDidFinishLaunching:(id)arg1
{
    %orig;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        /*id i;
        i = @[i];
        int* op = (int*)0x4141414141414141;
        *op = 5;*/
        
        dispatch_queue_t queue = dispatch_queue_create("MY QUEUE", 0);
        dispatch_async(queue, ^{
            //abort();
            /*int* op = (int*)0x4141414141414141;
            *op = 5;*/
            /*int* p = (int*)0x41;
            void (*v)(void) = (void (*)(void))p;
            v();
            id i;
            i = @[i];*/
            /*int* fP = (int*)test;
            *fP = 50;*/
        });
    });
}
%end
#endif
