#include <AppSupport/CPDistributedMessagingCenter.h>
#import <rocketbootstrap/rocketbootstrap.h>
@import ObjectiveC.objc_exception; //contains objc_exception_throw

#define isSB [[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.springboard"]

/* Gets the parent symbol of the crash (usually the method that caused the crash): */
static NSString* getLastSymbol()
{
    NSString* lastSymbol = [NSThread callStackSymbols][3];
    lastSymbol = [lastSymbol substringWithRange:NSMakeRange(4, lastSymbol.length - 4)];

    int startI = 0;
    int endI = 0;
    for (int i = 0; i < lastSymbol.length; i++)
    {
        char c = [lastSymbol characterAtIndex:i];
        if (c == ' ')
        {
            if (!startI)
            {
                startI = i;
            }
        }
        else
        {
            if (startI)
            {
                endI = i;
                break;
            }
        }
    }
    return [lastSymbol stringByReplacingCharactersInRange:NSMakeRange(startI, endI - startI) withString:@" - "];
}

static void writeStringToFile(NSString* str, NSString* path)
{
    if (isSB || [[NSFileManager defaultManager] isWritableFileAtPath:path])
    {
        [str writeToFile:path atomically:NO encoding:NSUTF8StringEncoding error:nil];
    }
    else
    {
        CPDistributedMessagingCenter* messagingCenter = [CPDistributedMessagingCenter centerNamed:@"com.muirey03.Cr4shedServer"];
        rocketbootstrap_distributedmessagingcenter_apply(messagingCenter);
        [messagingCenter sendMessageName:@"writeString" userInfo:@{@"string" : str, @"path" : path}];
    }
}

static void deleteFile(NSString* path)
{
    if (isSB || [[NSFileManager defaultManager] isWritableFileAtPath:path])
    {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
    else
    {
        CPDistributedMessagingCenter* messagingCenter = [CPDistributedMessagingCenter centerNamed:@"com.muirey03.Cr4shedServer"];
        rocketbootstrap_distributedmessagingcenter_apply(messagingCenter);
        [messagingCenter sendMessageName:@"deleteFile" userInfo:@{@"path" : path}];
    }
}

static NSString* createCrashLog(NSException* e)
{
    // Format the contents of the new crash log:
    NSString* lastSymbol = getLastSymbol();
    NSString* processID = [NSBundle mainBundle].bundleIdentifier;
    NSString* processName = [[NSProcessInfo processInfo] processName];

    //wtaf coreduetd?!
    if ([processID isEqualToString:@"com.apple.coreduetd"]) return nil;

    NSString* errorMessage = [NSString stringWithFormat:@"Date: %@\n"
                                                        @"Process: %@\n"
                                                        @"Bundle id: %@\n"
                                                        @"Exception type: %@\n"
                                                        @"Reason: %@\n"
                                                        @"Parent symbol: %@",
                                                        [NSDate date],
                                                        processName,
                                                        processID,
                                                        e.name,
                                                        e.reason,
                                                        lastSymbol];

    // Create the dir if it doesn't exist already:
    BOOL isDir;
    BOOL dirExists = [[NSFileManager defaultManager] fileExistsAtPath:@"/var/tmp/crash_logs" isDirectory:&isDir];
    if (!dirExists)
        isDir = [[NSFileManager defaultManager] createDirectoryAtURL:[NSURL fileURLWithPath:@"/var/tmp/crash_logs"] withIntermediateDirectories:YES attributes:nil error:nil];
    if (!isDir) return nil; //should never happen, but just in case

    // Get the date to use for the filename:
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd_HH:mm"];
    NSString* dateStr = [formatter stringFromDate:[NSDate date]];

    // Get the path for the new crash log:
    NSString* path = [NSString stringWithFormat:@"/var/tmp/crash_logs/%@@%@.log", processName, dateStr];
    for (int i = 1; [[NSFileManager defaultManager] fileExistsAtPath:path]; i++)
        path = [NSString stringWithFormat:@"/var/tmp/crash_logs/%@@%@ (%d).log", processName, dateStr, i];

    // Create the crash log
    writeStringToFile(errorMessage, path);

    return path;
}

// Called everytime a NSException is thrown
%hookf (void, objc_exception_throw, NSException* e)
{
    __block NSString* path = createCrashLog(e);
    if (path)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            //exception was caught, delete log:
            deleteFile(path);
        });
    }
    %orig;
}

#pragma mark Testing
#if 0
@interface SpringBoard
-(void)crash;
@end

%hook SpringBoard
-(void)applicationDidFinishLaunching:(id)arg1
{
    %orig;
    //@try {
    [self crash];
    //} @catch (NSException* e) {}
}
%end
#endif
