@import Foundation;

#include "AppSupport/CPDistributedMessagingCenter.h"
#import "rocketbootstrap/rocketbootstrap.h"
#import "MobileGestalt/MobileGestalt.h"
#import "symbolication.h"
#import "mach_exception.h"
#import <mach-o/dyld.h>

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

static NSString* determineCulprit(NSArray* symbols)
{
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
    NSString* systemVersion = (__bridge NSString*)MGCopyAnswer(CFSTR("ProductVersion"));
    if (systemVersion != nil)
    {
        return systemVersion;
    }
    return @"Unknown";
}

inline NSString* deviceName()
{
    return (__bridge NSString*)MGCopyAnswer(CFSTR("marketing-name"));
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
    const struct mach_header* header = _dyld_get_image_header(img);
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
    return 0;
}

static NSDate* getImageTime(uint32_t img)
{
    const struct mach_header* header = _dyld_get_image_header(img);
    BOOL is64bit = header->magic == MH_MAGIC_64 || header->magic == MH_CIGAM_64;
    uintptr_t cursor = (uintptr_t)header + (is64bit ? sizeof(struct mach_header_64) : sizeof(struct mach_header));
    const struct segment_command* segmentCommand = NULL;
    for (uint32_t i = 0; i < header->ncmds; i++, cursor += segmentCommand->cmdsize)
    {
        segmentCommand = (struct segment_command *)cursor;
        if (segmentCommand->cmd == LC_ID_DYLIB)
        {
            const struct dylib_command* dylibCommand = (const struct dylib_command*)segmentCommand;
            unsigned long timestamp = dylibCommand->dylib.timestamp;
            return [NSDate dateWithTimeIntervalSince1970:timestamp];
        }
    }
    return 0;
}


static void createCrashLog(NSString* specialisedInfo)
{
    // Format the contents of the new crash log:
    NSDate* now = [NSDate date];
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterShortStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    NSString* dateString = [formatter stringFromDate:now];

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
        NSDate* imgTime = getImageTime(i);
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateStyle:NSDateFormatterShortStyle];
        [formatter setTimeStyle:NSDateFormatterNoStyle];
        errorMessage = [errorMessage stringByAppendingFormat:@"%u: %s (%lu, Build date: %@)\n", i, _dyld_get_image_name(i), getImageVersion(i), [formatter stringFromDate:imgTime]];
    }

    // Create the dir if it doesn't exist already:
    BOOL isDir;
    BOOL dirExists = [[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Library/Cr4shed" isDirectory:&isDir];
    if (!dirExists)
        dirExists = createDir(@"/var/mobile/Library/Cr4shed");
    if (!dirExists) return; //should never happen, but just in case

    // Get the date to use for the filename:
    formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd_HH:mm"];
    NSString* dateStr = [formatter stringFromDate:now];

    // Get the path for the new crash log:
    NSString* path = [NSString stringWithFormat:@"/var/mobile/Library/Cr4shed/%@@%@.log", processName, dateStr];
    for (int i = 1; [[NSFileManager defaultManager] fileExistsAtPath:path]; i++)
        path = [NSString stringWithFormat:@"/var/mobile/Library/Cr4shed/%@@%@ (%d).log", processName, dateStr, i];

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
    NSString* info = [NSString stringWithFormat:@"Exception type: %@\n"
                                                @"Reason: %@\n"
                                                @"Culprit: %@\n"
                                                @"Call stack:\n%@",
                                                e.name,
                                                e.reason,
                                                culprit,
                                                stackSymbols];

    createCrashLog(info);
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

void handleMachException(struct exception_info* info)
{

    if (hasCrashed)
        return;

    NSString* culprit = determineCulprit(info->stackSymbols);
    NSArray* stackSymbolsArray = symbolicatedStackSymbols(info->stackSymbols, info->returnAddresses);
    NSString* stackSymbols = [stackSymbolsArray componentsJoinedByString:@"\n"];
    NSMutableString* infoStr = [NSMutableString stringWithFormat:   @"Exception type: %s\n"
                                                                    @"Exception subtype: %s\n"
                                                                    @"Exception codes: %s\n"
                                                                    @"Culprit: %@\n",
                                                                    info->exception_type,
                                                                    info->exception_subtype,
                                                                    info->exception_codes,
                                                                    culprit];
    if (info->vm_info)
        [infoStr appendFormat:@"VM Protection: %s\n\n", info->vm_info];
    [infoStr appendFormat:  @"Triggered by thread: %llu\n"
                            @"Thread name: %s\n"
                            @"Thread dispatch label: %s\n"
                            @"Call stack:\n%@\n\n"
                            @"Register values:\n",
                            info->thread_id,
                            info->thread_name,
                            info->thread_label,
                            stackSymbols];
    
    const unsigned int reg_columns = 3;
    const unsigned int column_width = 22;
    for (unsigned int i = 0; i < info->register_info.size(); i += reg_columns)
    {
        struct register_info reg_info = info->register_info[i];
        NSString* rowStr = [NSString stringWithFormat:@"%s: %p", reg_info.name, (void*)reg_info.value];

        if (i + 1 < info->register_info.size())
        {
            reg_info = info->register_info[i + 1];
            rowStr = [rowStr stringByPaddingToLength:column_width withString:@" " startingAtIndex:0];
            rowStr = [rowStr stringByAppendingFormat:@"%s: %p", reg_info.name, (void*)reg_info.value];
        }
        if (i + 2 < info->register_info.size())
        {
            reg_info = info->register_info[i + 2];
            rowStr = [rowStr stringByPaddingToLength:column_width * 2 withString:@" " startingAtIndex:0];
            rowStr = [rowStr stringByAppendingFormat:@"%s: %p", reg_info.name, (void*)reg_info.value];
        }
        if (i + 3 < info->register_info.size())
            rowStr = [rowStr stringByAppendingFormat:@"\n"];

        [infoStr appendString:rowStr];
    }

    createCrashLog([infoStr copy]);
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

#define UIApplicationDidFinishLaunchingNotification @"UIApplicationDidFinishLaunchingNotification"

BOOL isApplication(void)
{
    //is UIKit loaded:
    if (!objc_getClass("UIApplication"))
        return NO;
    
    //does executable link against UIKit:
    BOOL uikitLink = NO;
    const struct mach_header* header = _dyld_get_image_header(0);
    BOOL is64bit = header->magic == MH_MAGIC_64 || header->magic == MH_CIGAM_64;
    uintptr_t cursor = (uintptr_t)header + (is64bit ? sizeof(struct mach_header_64) : sizeof(struct mach_header));
    const struct segment_command* segmentCommand = NULL;
    for (uint32_t i = 0; i < header->ncmds; i++, cursor += segmentCommand->cmdsize)
    {
        segmentCommand = (struct segment_command *)cursor;
        switch (segmentCommand->cmd)
        {
            case LC_LOAD_DYLIB:
            case LC_LOAD_WEAK_DYLIB:
            case LC_REEXPORT_DYLIB:
                const struct dylib_command* dylibCommand = (const struct dylib_command*)segmentCommand;
                uint32_t offset = dylibCommand->dylib.name.offset;
                char* lib_name = ((char*)dylibCommand + offset);
                if (strcmp(lib_name, "/System/Library/Frameworks/UIKit.framework/UIKit") == 0)
                    uikitLink = YES;
                break;
        }
        if (uikitLink)
            break;
    }
    if (!uikitLink)
        return NO;
    
    //is executable path in an app dir?
    const char* exec_path = _dyld_get_image_name(0);
    #define STARTS_WITH(haystack, needle) (strstr(haystack, needle) == haystack)
    return STARTS_WITH(exec_path, "/Applications/") || STARTS_WITH(exec_path, "/var/containers/Bundle/Application/") || STARTS_WITH(exec_path, "/private/var/containers/Bundle/Application/") || (strcmp(exec_path, "/System/Library/CoreServices/SpringBoard.app/SpringBoard") == 0);
    #undef STARTS_WITH
}

%ctor
{
    if (!isBlacklisted([[NSProcessInfo processInfo] processName]))
    {
        %init(Tweak);
        NSSetUncaughtExceptionHandler(&unhandledExceptionHandler);

        if (isApplication())
        {
            [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:nil usingBlock:^(NSNotification* note){
                setMachExceptionHandler(&handleMachException);
            }];
        }
        else
            setMachExceptionHandler(&handleMachException);
    }
}