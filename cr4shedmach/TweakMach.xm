@import Foundation;

#include <stdlib.h>
#include <signal.h>
#include <uuid/uuid.h>
#include <mach/mach.h>
#import <substrate.h>
#import <symbolication.h>
#import <sharedutils.h>
#import <libnotifications.h>
#import "cr4shed_mach.h"
#import "mach_utils.h"

%hook CrashReport
%property (nonatomic, assign) time_t crashTime;
%property (nonatomic, assign) uint64_t __far;
%property (nonatomic, assign) struct exception_info* exceptionInfo;
%property (nonatomic, assign) mach_port_t realThread;
%property (nonatomic, assign) int realCrashedNumber;

//does any work that must be done before the process dies
//namely, finding the correct crashed thread and state
-(instancetype)initWithTask:(mach_port_t)task exceptionType:(exception_type_t)exception thread:(mach_port_t)thread threadStateFlavor:(int*)flavour threadState:(thread_state_t)old_state threadStateCount:(mach_msg_type_number_t)old_stateCnt
{
	/*
	There is a bug in ReportCrash, this code is here to fix it.
	`thread` seems to always be thread 0, not the actual crashed thread.
	This means that the exception type and codes are also wrong.

	The fix:
	To fix this, I inspect every thread's esr register,
	looking for the one that crashed. I can then get the far from this
	to use as codes[1], and I get the type and codes[0] from the
	UNIX signal.
	*/

	time_t crashTime = time(NULL);
	mach_port_t realThread = MACH_PORT_NULL;
	uint64_t far = 0;
	thread_act_port_array_t threads;
	mach_msg_type_number_t thread_count;
	task_threads(task, &threads, &thread_count);
	for (unsigned i = 0; i < thread_count; i++)
	{
		_STRUCT_ARM_EXCEPTION_STATE64 state = {0};
		mach_msg_type_number_t thread_stateCnt = ARM_EXCEPTION_STATE64_COUNT;
		kern_return_t kr = thread_get_state(threads[i], ARM_EXCEPTION_STATE64, (thread_state_t)&state, &thread_stateCnt);
		if (kr == KERN_SUCCESS && (state.__esr & 0xFC000000) != 0x54000000 && state.__esr != 0)
		{
			realThread = threads[i];
			far = state.__far;
			break;
		}
	}
	freeThreadArray(threads, thread_count);

	if ((self = %orig))
	{
		self.crashTime = crashTime;
		self.__far = far;
		if (realThread == MACH_PORT_NULL)
			realThread = thread;
		self.realThread = realThread;
		self.realCrashedNumber = thread_number(task, realThread);
		self.exceptionInfo = NULL;
	}
	return self;
}

%new
-(BOOL)cr4_isExceptionNonFatal
{
	if ([self respondsToSelector:@selector(isExceptionNonFatal)])
		return [self isExceptionNonFatal];
	return (!CR4GetIvar<void*>(self, "_exit_snapshot") && CR4GetIvar<mach_exception_data_t>(self, "_exceptionCode")[0] >> 58 != 10);
}

//responsible for gathering the exception info
-(void)loadBundleInfo
{
	%orig;

	//more work to fix ReportCrash's bug:
	exception_type_t exception = CR4GetIvar<exception_type_t>(self, "_exceptionType");
	mach_exception_data_t old_exception_codes = CR4GetIvar<mach_exception_data_t>(self, "_exceptionCode");
	mach_exception_data_t exception_codes = (mach_exception_data_t)calloc(2, sizeof(mach_exception_data_type_t));
	if (!exception_codes) return;
	mach_msg_type_number_t codeCnt = CR4GetIvar<mach_msg_type_number_t>(self, "_exceptionCodeCount");
	if (old_exception_codes)
		memcpy(exception_codes, old_exception_codes, codeCnt * sizeof(mach_exception_data_type_t));
	mach_port_t task = CR4GetIvar<mach_port_t>(self, "_task");
	mach_port_t thread = CR4GetIvar<mach_port_t>(self, "_threadPort");
	int threadNum = CR4GetIvar<int>(self, "_crashedThreadNumber");
	int sig = CR4GetIvar<int>(self, "_signal");
	
	//don't create report if cr4shed already generated an NSException report
	if (processHasBeenHandled(task) || sig == 0 || sig == SIGKILL || isBlacklisted(self.procName))
		return;
	
	mach_exception_data_type_t subtype = 0;
	exception = mach_exception_type(sig, &subtype);
	exception_codes[0] = subtype;
	if (exception == EXC_CORPSE_NOTIFY)
	{
		exception_codes[1] = (mach_exception_data_type_t)self.__far;
		if (exception == EXC_BAD_ACCESS)
		{
			thread = self.realThread;
			threadNum = self.realCrashedNumber;
		}
	}

	if (![self cr4_isExceptionNonFatal])
	{
		struct exception_info* info = (struct exception_info*)malloc(sizeof(struct exception_info));
		memset((void*)info, 0, sizeof(struct exception_info));

		//get basic info from crash:
		info->processName = self.procName;
		info->bundleID = CR4GetIvar<NSString*>(self, "_bundle_id");
		info->exception_type = mach_exception_string(exception, [self signalName]);
		info->exception_subtype = mach_code_string(exception, exception_codes, codeCnt);
		info->exception_codes = mach_exception_codes_string(exception_codes, codeCnt);
		info->vm_info = mach_exception_vm_info(task, exception, exception_codes, codeCnt);
		NSArray* threadNames = CR4GetIvar<NSMutableArray*>(self, "_threadNames");
		info->thread_num = threadNum;
		info->thread_name = threadNames.count > threadNum ? threadNames[threadNum] : nil;
		info->register_info = get_register_info(thread);

		//get annotation:
		NSString* libSwiftPath = nil;
		mach_vm_address_t staticAnnotationAddr = findSymbolInTask(task, "_gCRAnnotations", @"libswiftCore.dylib", &libSwiftPath);
		NSString* swiftErrorMessage = nil;
		if (staticAnnotationAddr && libSwiftPath.length)
		{
			NSArray* images = CR4GetIvar<NSArray*>(self, "_binaryImages");
			mach_vm_address_t annotationAddr = 0;
			for (NSDictionary* img in images)
			{
				if ([img[@"ExecutablePath"] isEqualToString:libSwiftPath])
				{
					uint64_t start = [img[@"StartAddress"] unsignedLongLongValue];
					annotationAddr = staticAnnotationAddr + start;
					break;
				}
			}

			if (annotationAddr)
			{
				mach_vm_address_t msgAddr = 0;
				rread(task, annotationAddr + offsetof(crashreporter_annotations_t, message), &msgAddr, sizeof(mach_vm_address_t));
				if (msgAddr)
				{
					swiftErrorMessage = [self _readStringAtTaskAddress:msgAddr immutableOnly:NO maxLength:0];
					if ([swiftErrorMessage hasSuffix:@"\n"])
						swiftErrorMessage = [swiftErrorMessage substringWithRange:NSMakeRange(0, swiftErrorMessage.length - 1)];
				}
			}
		}
		info->swiftErrorMessage = swiftErrorMessage;

		//get unsymbolicated backtrace:
		__block NSMutableArray* callStackSymbols = nil;
		__block NSInteger i = 0;
		[self decodeBacktraceWithBlock:^(NSInteger unused, NSArray* symbols){
			if (i++ == threadNum)
				callStackSymbols = [symbols mutableCopy];
		}];

		//symbolicate backtrace:
		NSArray* backtraces = CR4GetIvar<NSArray*>(self, "_backtraces");
		NSArray* returnAddresses = backtraces.count > threadNum ? backtraces[threadNum] : nil;
		if (callStackSymbols && returnAddresses)
		{
			if ([[callStackSymbols firstObject] hasPrefix:@"Thread"])
				[callStackSymbols removeObjectAtIndex:0];
			if ([[callStackSymbols firstObject] hasPrefix:@"Thread"])
				[callStackSymbols removeObjectAtIndex:0];
			
			NSUInteger count = MIN(callStackSymbols.count, returnAddresses.count);
			for (NSUInteger si = 0; si < count; si++)
			{
				uint64_t addr = [returnAddresses[si][@"Address"] unsignedLongLongValue];
				NSDictionary* imgDict = [self binaryImageDictionaryForAddress:addr];
				NSString* archStr = imgDict[@"BinaryInfoArchitectureKey"];
				CSArchitecture arch = archStr.length ? CSArchitectureGetArchitectureForName([archStr UTF8String]) : CSArchitectureGetCurrent();
				uuid_t uuid; 
				const void* binaryUUID = [imgDict[@"BinaryInfoDwarfUUIDKey"] bytes];
				if (binaryUUID)
				{
					memcpy((void*)uuid, binaryUUID, 16);
					char* uuid_cstr = (char*)malloc(37);
					uuid_cstr[36] = '\0';
					uuid_unparse(uuid, uuid_cstr);
					if (uuid_cstr)
					{
						//calculate padding
						NSArray* comp = [callStackSymbols[si] componentsSeparatedByString:@" "];
						NSString* str = [[comp subarrayWithRange:NSMakeRange(0, comp.count - 1)] componentsJoinedByString:@" "];
						NSUInteger padding = str.length + 12;

						NSString* uuidStr = [NSString stringWithUTF8String:uuid_cstr];
						NSString* symbol = nameForRemoteSymbol(addr, imgDict[@"ExecutablePath"], uuidStr, [imgDict[@"StartAddress"] unsignedLongLongValue], arch);
						callStackSymbols[si] = [callStackSymbols[si] stringByPaddingToLength:padding withString:@" " startingAtIndex:0];
						if (symbol)
							callStackSymbols[si] = [callStackSymbols[si] stringByAppendingFormat:@"\t// %@", symbol];
						free(uuid_cstr);
					}
				}
			}
		}

		info->stackSymbols = [callStackSymbols copy];
		self.exceptionInfo = info;
		if (exception_codes)
			free((void*)exception_codes);
	}
}

//responsible for creating the report
%new
-(void)generateCr4shedReport
{
	if (self.exceptionInfo)
	{
		struct exception_info* info = self.exceptionInfo;
		NSArray* images = CR4GetIvar<NSArray*>(self, "_binaryImages");
		NSString* terminationReason = CR4GetIvar<NSString*>(self, "_terminator_reason");

		time_t crashTime = self.crashTime;
		NSString* dateString = stringFromTime(crashTime, CR4DateFormatPretty);
		NSString* device = [NSString stringWithFormat:@"%@, iOS %@", deviceName(), deviceVersion()];

		NSMutableString* logStr = [NSMutableString stringWithFormat:@"Date: %@\n"
															@"Process: %@\n"
															@"Bundle id: %@\n"
															@"Device: %@\n",
															dateString,
															info->processName,
															info->bundleID,
															device];
		
		NSString* versionString = CR4GetIvar<NSString*>(self, "_short_vers");
		if (!versionString.length)
			versionString = CR4GetIvar<NSString*>(self, "_bundle_vers");
		if (versionString.length)
			[logStr appendFormat:@"Bundle version: %@\n", versionString];
		
		NSString* culprit = determineCulprit(info->stackSymbols);
		NSString* stackSymbols = [info->stackSymbols componentsJoinedByString:@"\n"];
		[logStr appendFormat:  	@"\nException type: %@\n"
								@"Exception subtype: %s\n"
								@"Exception codes: %s\n"
								@"Culprit: %@\n",
								info->exception_type,
								info->exception_subtype,
								info->exception_codes,
								culprit];
		if (info->swiftErrorMessage)
			[logStr appendFormat:@"Swift Error Message: %@\n", info->swiftErrorMessage];
		if (info->vm_info)
			[logStr appendFormat:@"VM Protection: %s\n", info->vm_info];
		if (terminationReason.length)
			[logStr appendFormat:@"Termination Reason: %@\n", terminationReason];
		[logStr appendString:@"\n"];
		[logStr appendFormat:  @"Triggered by thread: %llu\n"
								@"Thread name: %@\n"
								@"Call stack:\n%@\n\n"
								@"Register values:\n",
								info->thread_num,
								info->thread_name,
								stackSymbols];
		
		//register info:
		const unsigned reg_columns = 3;
		const unsigned column_width = 24;
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

			[logStr appendString:rowStr];
		}

		//image infos:
		[logStr appendString:@"\n\nLoaded images:\n"];
		NSUInteger imageCount = images.count;
		for (NSUInteger i = 0; i < imageCount; i++)
		{
			[logStr appendFormat:@"%llu: %@\n", (unsigned long long)i, images[i][@"ExecutablePath"]];
		}

		 //extra info for the GUI to parse easily:
		NSDictionary* extraInfo = @{
			@"ProcessName" : info->processName ?: @"",
			@"ProcessBundleID" : info->bundleID ?: @"",
			@"Culprit" : culprit ?: @"Unknown"
		};
		logStr = [addInfoToLog(logStr, extraInfo) mutableCopy];

		// Create the dir if it doesn't exist already:
		BOOL isDir;
		BOOL dirExists = [[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Library/Cr4shed" isDirectory:&isDir];
		if (!dirExists)
			dirExists = createDir(@"/var/mobile/Library/Cr4shed");
		if (!dirExists) return; //should never happen, but just in case

		// Get the date to use for the filename:
		NSString* filenameDateStr = stringFromTime(crashTime, CR4DateFormatFilename);

		// Get the path for the new crash log:
		NSString* path = [NSString stringWithFormat:@"/var/mobile/Library/Cr4shed/%@@%@.log", info->processName, filenameDateStr];
		for (unsigned i = 1; [[NSFileManager defaultManager] fileExistsAtPath:path]; i++)
			path = [NSString stringWithFormat:@"/var/mobile/Library/Cr4shed/%@@%@ (%d).log", info->processName, filenameDateStr, i];

		// Create the crash log
		writeStringToFile(logStr, path);

		//notification:
		NSString* notifContent = [NSString stringWithFormat:@"%@ crashed at %@", info->processName, dateString];
		NSString* bundleID = @"com.muirey03.cr4shedgui";
		NSString* title = @"Cr4shed";
		NSDictionary* notifUserInfo = @{@"logPath" : path};
		[CPNotification showAlertWithTitle:title
									message:notifContent
									userInfo:notifUserInfo
									badgeCount:1
									soundName:nil
									delay:0.
									repeats:NO
									bundleId:bundleID];

		if (info->exception_subtype)
			free((void*)info->exception_subtype);
		if (info->exception_codes)
			free((void*)info->exception_codes);
		if (info->vm_info)
			free((void*)info->vm_info);
		for (unsigned i = 0; i < info->register_info.size(); i++)
		{
			struct register_info reg_info = info->register_info[i];
			if (reg_info.name) free((void*)reg_info.name);
		}
		free(self.exceptionInfo);
		self.exceptionInfo = NULL;
	}
}

-(void)generateLogAtLevel:(BOOL)arg1 withBlock:(id)arg2
{
	%orig;
	[self generateCr4shedReport];
}

-(void)generateCustomLogAtLevel:(BOOL)arg1 withBlock:(id)arg2
{
	%orig;
	[self generateCr4shedReport];
}
%end
