@import Foundation;

#include "AppSupport/CPDistributedMessagingCenter.h"
#import "rocketbootstrap/rocketbootstrap.h"
#import "symbolication.h"
#import "sharedutils.h"
#import <mach-o/dyld.h>
#import <mach/mach.h>

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

@interface Cr4shedServer : NSObject
+ (id)sharedInstance;
-(NSDictionary*)sendNotification:(NSString*)name withUserInfo:(NSDictionary*)userInfo;
@end

void sendNotification(NSString* content, NSDictionary* userInfo)
{
    if (isSB)
    {
        [[%c(Cr4shedServer) sharedInstance] sendNotification:nil withUserInfo:@{@"content" : content}];
    }
    else
    {
        CPDistributedMessagingCenter* messagingCenter = [CPDistributedMessagingCenter centerNamed:@"com.muirey03.Cr4shedServer"];
        rocketbootstrap_distributedmessagingcenter_apply(messagingCenter);
        [messagingCenter sendMessageName:@"sendNotification" userInfo:@{@"content" : content, @"userInfo" : userInfo}];
    }
}

static unsigned long getImageVersion(uint32_t img)
{
    if (img < _dyld_image_count())
    {
        const struct mach_header* header = _dyld_get_image_header(img);
        if (header)
        {
            BOOL is64bit = header->magic == MH_MAGIC_64 || header->magic == MH_CIGAM_64;
            uintptr_t cursor = (uintptr_t)header + (is64bit ? sizeof(struct mach_header_64) : sizeof(struct mach_header));
            const struct segment_command* segmentCommand = NULL;
            for (uint32_t i = 0; i < header->ncmds; i++, cursor += segmentCommand->cmdsize)
            {
                segmentCommand = (struct segment_command *)cursor;
                if (segmentCommand->cmd == LC_ID_DYLIB)
                {
                    const struct dylib_command* dylibCommand = (const struct dylib_command*)segmentCommand;
                    return dylibCommand->dylib.current_version;
                }
            }
        }
    }
    return 0;
}

static void createCrashLog(NSString* specialisedInfo)
{
    markProcessAsHandled(mach_task_self());

    // Format the contents of the new crash log:
    NSDate* now = [NSDate date];
    NSString* dateString = stringFromDate(now, CR4DateFormatPretty);

    NSString* processID = [NSBundle mainBundle].bundleIdentifier;
    NSString* processName = [[NSProcessInfo processInfo] processName];
    NSString* device = [NSString stringWithFormat:@"%@, iOS %@", deviceName(), deviceVersion()];

    NSString* errorMessage = [NSString stringWithFormat:@"Date: %@\n"
                                                        @"Process: %@\n"
                                                        @"Bundle id: %@\n"
                                                        @"Device: %@\n\n"
                                                        @"%@\n\n"
                                                        @"Loaded images:\n",
                                                        dateString,
                                                        processName,
                                                        processID,
                                                        device,
                                                        specialisedInfo];

    uint32_t image_cnt = _dyld_image_count();
    for (unsigned int i = 0; i < image_cnt; i++)
    {
        errorMessage = [errorMessage stringByAppendingFormat:@"%u: %s (Version: %lu)\n", i, _dyld_get_image_name(i), getImageVersion(i)];
    }

    // Create the dir if it doesn't exist already:
    BOOL isDir;
    BOOL dirExists = [[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Library/Cr4shed" isDirectory:&isDir];
    if (!dirExists)
        dirExists = createDir(@"/var/mobile/Library/Cr4shed");
    if (!dirExists) return; //should never happen, but just in case

    // Get the date to use for the filename:
    NSString* filenameDateStr = stringFromDate(now, CR4DateFormatFilename);

    // Get the path for the new crash log:
    NSString* path = [NSString stringWithFormat:@"/var/mobile/Library/Cr4shed/%@@%@.log", processName, filenameDateStr];
    for (unsigned i = 1; [[NSFileManager defaultManager] fileExistsAtPath:path]; i++)
        path = [NSString stringWithFormat:@"/var/mobile/Library/Cr4shed/%@@%@ (%d).log", processName, filenameDateStr, i];

    // Create the crash log
    writeStringToFile(errorMessage, path);

    //show notification:
    NSDictionary* notifUserInfo = @{@"logPath" : path};
    sendNotification([NSString stringWithFormat:@"%@ crashed at %@", processName, dateString], notifUserInfo);
}

/* add the exception handler: */
static NSUncaughtExceptionHandler* oldHandler;
static BOOL hasCrashed = NO;

void createNSExceptionLog(NSException* e)
{
    /* Remove false positives: */
    if ([e.reason containsString:@"optimistic locking failure"])
        return;
    if ([e.reason containsString:@"This NSPersistentStoreCoordinator has no persistent stores"])
        return;

    NSString* culprit = determineCulprit(e.callStackSymbols);
    NSString* stackSymbols = getCallStack(e);
    NSMutableString* info = [NSMutableString stringWithFormat:  @"Exception type: %@\n"
                                                                @"Reason: %@\n"
                                                                @"Culprit: %@\n\n",
                                                                e.name,
                                                                e.reason,
                                                                culprit];

    NSDictionary* excUserInfo = e.userInfo;
    if (excUserInfo.allKeys.count)
    {
        NSMutableString* userInfoStr = [@"User info:\n" mutableCopy];
        for (NSString* key in excUserInfo.allKeys)
        {
            NSString* objStr = [excUserInfo[key] description];
            //if it is multi-line, insert a '\n' at the start
            if ([objStr componentsSeparatedByString:@"\n"].count > 1)
                objStr = [@"\n" stringByAppendingString:objStr];
            if (!objStr.length) objStr = @"N/A";
            [userInfoStr appendFormat:@"%@: %@\n", key, objStr];
        }
        [userInfoStr appendString:@"\n"];
        [info appendString:userInfoStr];
    }

    [info appendFormat:@"Call stack:\n%@", stackSymbols];
    createCrashLog([info copy]);
}

void unhandledExceptionHandler(NSException* e)
{
    if (hasCrashed)
        abort();
    else
        hasCrashed = YES;
    @try
    {
        createNSExceptionLog(e);
        if (oldHandler)
        {
            oldHandler(e);
        }
    }
    @catch (NSException* e)
    {
        abort();
    }
}

%group Tweak
%hookf (void, NSSetUncaughtExceptionHandler, NSUncaughtExceptionHandler* handler)
{
    if (handler != &unhandledExceptionHandler)
    {
        oldHandler = handler;
        return;
    }
    %orig;
}
%end

inline BOOL isBlacklisted(NSString* procName)
{
    NSArray<NSString*>* blacklisted = @[
        @"ProtectedCloudKeySyncing",
        @"gssc",
        @"awdd",
        @"biometrickitd",
        @"spindump",
        @"keybagd",
        @"ReportMemoryException",
        @"nsurlsessiond",
        @"locationd",
        @"coreduetd",
        @"mDNSResponder",
        @"hangreporter",
        @"nanoregistrylaunchd",
        @"nanoregistryd",
        @"mobilewatchdog",
        @"misd",
        @"dasd",
        @"passd",
        @"CircleJoinRequested"
    ];
    for (NSString* bannedProc in blacklisted)
    {
        if ([procName isEqualToString:bannedProc])
            return YES;
    }
    return NO;
}

%ctor
{
    if ([[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.springboard"])
        dlopen("/Library/MobileSubstrate/DynamicLibraries/__Cr4shedSB.dylib", RTLD_NOW);

    if (!isBlacklisted([[NSProcessInfo processInfo] processName]))
    {
        %init(Tweak);
        NSSetUncaughtExceptionHandler(&unhandledExceptionHandler);
    }
}
