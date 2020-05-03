@import Foundation;

#import <MRYIPCCenter.h>
#import <sharedutils.h>
#import "symbolication.h"
#import <mach-o/dyld.h>
#import <mach/mach.h>

@interface Cr4shedServer : NSObject
+ (id)sharedInstance;
-(NSDictionary*)sendNotification:(NSDictionary*)userInfo;
-(NSDictionary*)writeString:(NSDictionary*)userInfo;
@end

static NSString* writeStringToFile(NSString* str, NSString* filename)
{
	NSDictionary* reply;
	if (%c(Cr4shedServer))
	{
		reply = [[%c(Cr4shedServer) sharedInstance] writeString:@{@"string" : str, @"filename" : filename}];
	}
	else
	{
		MRYIPCCenter* ipcCenter = [MRYIPCCenter centerNamed:@"com.muirey03.cr4sheddserver"];
		reply = [ipcCenter callExternalMethod:@selector(writeString:) withArguments:@{@"string" : str, @"filename" : filename}];
	}
	return reply[@"path"];
}

static NSString* getCallStack(NSException* e)
{
	NSArray* symbols = symbolicatedException(e);
	NSString* symbolStr = [symbols componentsJoinedByString:@"\n"];
	return symbolStr;
}

static void sendNotification(NSString* content, NSDictionary* userInfo)
{
	if (%c(Cr4shedServer))
	{
		[[%c(Cr4shedServer) sharedInstance] sendNotification:@{@"content" : content}];
	}
	else
	{
		MRYIPCCenter* ipcCenter = [MRYIPCCenter centerNamed:@"com.muirey03.cr4sheddserver"];
		[ipcCenter callExternalMethod:@selector(sendNotification:) withArguments:@{@"content" : content, @"userInfo" : userInfo}];
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

static void createCrashLog(NSString* specialisedInfo, NSMutableDictionary* extraInfo)
{
	if (isBlacklisted()) return;

	markProcessAsHandled();

	// Format the contents of the new crash log:
	NSDate* now = [NSDate date];
	NSString* dateString = stringFromDate(now, CR4DateFormatPretty);

	NSString* processID = [NSBundle mainBundle].bundleIdentifier;
	NSString* processName = [[NSProcessInfo processInfo] processName];
	NSString* device = [NSString stringWithFormat:@"%@, iOS %@", deviceName(), deviceVersion()];
	NSBundle* bundle = [NSBundle mainBundle];
	NSString* versionString = bundle.infoDictionary[@"CFBundleShortVersionString"];
	if (!versionString)
		versionString = bundle.infoDictionary[@"CFBundleVersion"];

	NSMutableString* errorMessage = [NSMutableString stringWithFormat:  @"Date: %@\n"
																		@"Process: %@\n"
																		@"Bundle id: %@\n"
																		@"Device: %@\n",
																		dateString,
																		processName,
																		processID,
																		device];

	if (versionString.length)
		[errorMessage appendFormat:@"Bundle version: %@\n", versionString];
	[errorMessage appendFormat: @"\n%@\n\n"
								@"Loaded images:\n",
								specialisedInfo];

	//add image infos:
	uint32_t image_cnt = _dyld_image_count();
	for (unsigned int i = 0; i < image_cnt; i++)
	{
		[errorMessage appendFormat:@"%u: %s (Version: %lu)\n", i, _dyld_get_image_name(i), getImageVersion(i)];
	}

	//extra info for the GUI to parse easily:
	if (!extraInfo) extraInfo = [NSMutableDictionary new];
	[extraInfo addEntriesFromDictionary:@{
		@"ProcessName" : processName ?: @"",
		@"ProcessBundleID" : processID ?: @""
	}];
	errorMessage = [addInfoToLog(errorMessage, [extraInfo copy]) mutableCopy];

	// Get the date to use for the filename:
	NSString* filenameDateStr = stringFromDate(now, CR4DateFormatFilename);

	// Get the filename for the new crash log:
	NSString* filename = [NSString stringWithFormat:@"%@@%@", processName, filenameDateStr];

	// Create the crash log
	NSString* path = writeStringToFile(errorMessage, filename);
	if (!path)
		return;

	//show notification:
	NSDictionary* notifUserInfo = @{@"logPath" : path};
	sendNotification([NSString stringWithFormat:@"%@ crashed at %@", processName, dateString], notifUserInfo);
}

/* add the exception handler: */
static NSUncaughtExceptionHandler* oldHandler = NULL;

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

	//user info (for Supercharge):
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
	
	NSMutableDictionary* extraInfo = [@{
		@"Culprit" : culprit ?: @"Unknown",
		@"NSExceptionReason" : e.reason ?: @""
	} mutableCopy];
	createCrashLog([info copy], extraInfo);
}

void unhandledExceptionHandler(NSException* e)
{
	@autoreleasepool
	{
		static BOOL hasCrashed = NO;
		if (hasCrashed)
			exit(EXIT_FAILURE);
		else
			hasCrashed = YES;
		@try
		{
			createNSExceptionLog(e);
		}
		@catch (NSException* e)
		{
			exit(EXIT_FAILURE);
		}
		if (oldHandler)
			oldHandler(e);
	}
}

%group Tweak
%hookf (void, NSSetUncaughtExceptionHandler, NSUncaughtExceptionHandler* handler)
{
	@autoreleasepool
	{
		if (handler != &unhandledExceptionHandler)
		{
			oldHandler = handler;
			return;
		}
		%orig;
	}
}

%hookf (NSUncaughtExceptionHandler*, NSGetUncaughtExceptionHandler)
{
	@autoreleasepool
	{
		return oldHandler;
	}
}
%end

inline BOOL isHardBlacklisted(NSString* procName)
{
	if (!procName)
		return YES;
	
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
		@"CircleJoinRequested",
		@"suggestd"
	];
	for (NSString* bannedProc in blacklisted)
	{
		if (bannedProc && [procName isEqualToString:bannedProc])
			return YES;
	}
	return NO;
}

%ctor
{
	@autoreleasepool
	{
		if ([[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.springboard"])
			dlopen("/Library/MobileSubstrate/DynamicLibraries/Cr4shedSB.dylib", RTLD_NOW);

		if (!isHardBlacklisted([[NSProcessInfo processInfo] processName]))
		{
			oldHandler = NSGetUncaughtExceptionHandler();
			NSSetUncaughtExceptionHandler(&unhandledExceptionHandler);
			%init(Tweak);
		}
	}
}
