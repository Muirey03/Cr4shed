#include <AppSupport/CPDistributedMessagingCenter.h>
#import <rocketbootstrap/rocketbootstrap.h>

@interface Cr4shedServer : NSObject
@end

@implementation Cr4shedServer

+ (void)load {
	[self sharedInstance];
}

+ (id)sharedInstance {
	static dispatch_once_t once = 0;
	__strong static id sharedInstance = nil;
	dispatch_once(&once, ^{
		sharedInstance = [[self alloc] init];
	});
	return sharedInstance;
}

- (id)init {
	if ((self = [super init])) {
        CPDistributedMessagingCenter* messagingCenter = [CPDistributedMessagingCenter centerNamed:@"com.muirey03.Cr4shedServer"];
        rocketbootstrap_distributedmessagingcenter_apply(messagingCenter);
        [messagingCenter runServerOnCurrentThread];

		[messagingCenter registerForMessageName:@"writeString" target:self selector:@selector(writeString:withUserInfo:)];
	}

	return self;
}

-(NSDictionary*)writeString:(NSString*)name withUserInfo:(NSDictionary*)userInfo
{
    NSString* str = userInfo[@"string"];
    NSString* path = userInfo[@"path"];
    [str writeToFile:path atomically:NO encoding:NSUTF8StringEncoding error:nil];
    return nil;
}
@end

%ctor
{
    [Cr4shedServer load];
}
