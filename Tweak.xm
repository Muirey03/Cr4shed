#include <AppSupport/CPDistributedMessagingCenter.h>
#import <rocketbootstrap/rocketbootstrap.h>
#import "symbolication.h"

#define isSB [[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.springboard"]

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

static BOOL createDir(NSString* path)
{
    if (isSB || [[NSFileManager defaultManager] isWritableFileAtPath:path])
    {
        return [[NSFileManager defaultManager] createDirectoryAtURL:[NSURL fileURLWithPath:path] withIntermediateDirectories:YES attributes:nil error:nil];
    }
    CPDistributedMessagingCenter* messagingCenter = [CPDistributedMessagingCenter centerNamed:@"com.muirey03.Cr4shedServer"];
    rocketbootstrap_distributedmessagingcenter_apply(messagingCenter);
    NSDictionary* reply = [messagingCenter sendMessageAndReceiveReplyName:@"createDir" userInfo:@{@"path" : path}];
    return [reply[@"success"] boolValue];
}

static NSString* getCallStack(NSException* e)
{
    NSArray* symbols = symbolicatedCallStack(e);
    NSString* symbolStr = [symbols componentsJoinedByString:@"\n"];
    return symbolStr;
}

static NSString* getImage(NSString* symbol)
{
    int startingI = -1;
    int endingI = -1;
    for (int i = 0; i < symbol.length - 1; i++)
    {
        char c = [symbol characterAtIndex:i];
        char nextC = [symbol characterAtIndex:i+1];
        if (startingI == -1)
        {
            if (c == ' ' && nextC != ' ')
            {
                startingI = i+1;
            }
        }
        else
        {
            if (nextC == ' ')
            {
                endingI = i+1;
                break;
            }
        }
    }
    return [symbol substringWithRange:NSMakeRange(startingI, endingI-startingI)];
}

static NSString* determineCulprit(NSException* e)
{
    NSArray* symbols = [e callStackSymbols];
    for (int i = 0; i < symbols.count; i++)
    {
        NSString* symbol = symbols[i];
        NSString* image = getImage(symbol);
        if (![image isEqualToString:@"Cr4shed.dylib"])
        {
            if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/Library/MobileSubstrate/DynamicLibraries/%@", image]])
                return image;
        }
    }
    return @"Unknown";
}

inline NSString* deviceVersion()
{
    return [[UIDevice currentDevice] systemVersion];
}

inline NSString* deviceName()
{
    return (__bridge NSString*)MGCopyAnswer(CFSTR("marketing-name"));
}

@interface Cr4shedServer : NSObject
+ (id)sharedInstance;
-(NSDictionary*)sendNotification:(NSString*)name withUserInfo:(NSDictionary*)userInfo;
@end

void sendNotification(NSString* content)
{
    if (isSB)
    {
        [[%c(Cr4shedServer) sharedInstance] sendNotification:nil withUserInfo:@{@"content" : content}];
    }
    else
    {
        CPDistributedMessagingCenter* messagingCenter = [CPDistributedMessagingCenter centerNamed:@"com.muirey03.Cr4shedServer"];
        rocketbootstrap_distributedmessagingcenter_apply(messagingCenter);
        [messagingCenter sendMessageName:@"sendNotification" userInfo:@{@"content" : content}];
    }
}

static NSString* createCrashLog(NSException* e)
{
    // Format the contents of the new crash log:
    NSString* stackSymbols = getCallStack(e);
    NSString* processID = [NSBundle mainBundle].bundleIdentifier;
    NSString* processName = [[NSProcessInfo processInfo] processName];
    NSString* culprit = determineCulprit(e);
    NSString* device = [NSString stringWithFormat:@"%@, iOS %@", deviceName(), deviceVersion()];

    NSString* errorMessage = [NSString stringWithFormat:@"Date: %@\n"
                                                        @"Process: %@\n"
                                                        @"Bundle id: %@\n"
                                                        @"Exception type: %@\n"
                                                        @"Reason: %@\n"
                                                        @"Culprit: %@\n"
                                                        @"Device: %@\n"
                                                        @"Call stack:\n%@",
                                                        [NSDate date],
                                                        processName,
                                                        processID,
                                                        e.name,
                                                        e.reason,
                                                        culprit,
                                                        device,
                                                        stackSymbols];

    // Create the dir if it doesn't exist already:
    BOOL isDir;
    BOOL dirExists = [[NSFileManager defaultManager] fileExistsAtPath:@"/var/tmp/crash_logs" isDirectory:&isDir];
    if (!dirExists)
        isDir = createDir(@"/var/tmp/crash_logs");
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

    //show notification: TODO:
    sendNotification([NSString stringWithFormat:@"%@ crashed at %@", processName, [NSDate date]]);

    return path;
}

/* add the exception handler: */
static NSUncaughtExceptionHandler* oldHandler;

__unused void unhandledExceptionHandler(NSException* e)
{
    createCrashLog(e);
    if (oldHandler)
    {
        oldHandler(e);
    }
}

%hookf (void, NSSetUncaughtExceptionHandler, NSUncaughtExceptionHandler* handler)
{
    if (handler != &unhandledExceptionHandler)
    {
        oldHandler = handler;
        return;
    }
    %orig;
}

%ctor
{
    NSSetUncaughtExceptionHandler(&unhandledExceptionHandler);
}
