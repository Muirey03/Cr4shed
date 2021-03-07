@import Foundation;
#import <sharedutils.h>
#import <MRYIPCCenter.h>
#import "../cr4shedmach/mach_utils.h"
#import "cr4shed_jetsam.h"

static NSString* serverWriteStringToFile(NSString* str, NSString* filename)
{
	MRYIPCCenter* ipcCenter = [MRYIPCCenter centerNamed:@"com.muirey03.cr4sheddserver"];
	NSDictionary* reply = [ipcCenter callExternalMethod:@selector(writeString:) withArguments:@{@"string" : str, @"filename" : filename}];
	return reply[@"path"];
}

%hook MemoryResourceException
-(BOOL)extractCorpseInfo
{
	BOOL ret = %orig;
	MRYIPCCenter* ipcCenter = [MRYIPCCenter centerNamed:@"com.muirey03.cr4sheddserver"];
	NSNumber* blacklistedBool = [ipcCenter callExternalMethod:@selector(isProcessBlacklisted:) withArguments:self.execName];
	if (!blacklistedBool.boolValue)
	{
		[self extractBacktraceInfo];
		[self generateCr4shedReport];
	}
	return ret;
}

%new
-(void)generateCr4shedReport
{
	time_t crashTime = [self.startTime timeIntervalSince1970];
	NSString* dateString = stringFromTime(crashTime, CR4DateFormatPretty);
	NSString* device = [NSString stringWithFormat:@"%@, iOS %@", deviceName(), deviceVersion()];
	NSString* const reason = @"The process was terminated for exceeding jetsam memory limits";
	NSMutableString* logStr = [NSMutableString stringWithFormat:@"Date: %@\n"
																@"Process: %@\n"
																@"Bundle id: %@\n"
																@"Device: %@\n\n"
																@"Reason: %@\n"
																@"Uptime: %llds\n",
																dateString,
																self.execName,
																self.bundleID,
																device,
																reason,
																(long long)self.upTime];

	[logStr appendFormat:@"%@", [self fetchMemoryInfo]];
	if ([logStr characterAtIndex:logStr.length - 1] != '\n')
		[logStr appendString:@"\n"];
	[logStr appendFormat:@"\n%@", [self prettyPrintBinaryImages]];

	NSDictionary* extraInfo = @{
		@"NSExceptionReason" : reason,
		@"ProcessName" : self.execName ?: @"",
		@"ProcessBundleID" : self.bundleID ?: @""
	};
	logStr = [addInfoToLog(logStr, extraInfo) mutableCopy];

	// Get the date to use for the filename:
	NSString* filenameDateStr = stringFromTime(crashTime, CR4DateFormatFilename);

	// Get the path for the new crash log:
	NSString* path = [NSString stringWithFormat:@"%@@%@", self.execName, filenameDateStr];

	// Create the crash log
	serverWriteStringToFile(logStr, path);
}

%new
-(NSString*)fetchMemoryInfo
{
	NSMutableString* memoryInfo = [NSMutableString new];
	mach_port_t task = self.task;
	struct task_basic_info taskInfo;
	mach_msg_type_number_t count = TASK_BASIC_INFO_COUNT;
	kern_return_t kr = task_info(task, TASK_BASIC_INFO, (task_info_t)&taskInfo, &count);
	if (kr == KERN_SUCCESS)
	{
		[memoryInfo appendFormat:@"Virtual memory size: 0x%zx bytes\n", (size_t)taskInfo.virtual_size];
		[memoryInfo appendFormat:@"Resident memory size: 0x%zx bytes\n", (size_t)taskInfo.resident_size];
		
		thread_act_array_t threads = NULL;
		mach_msg_type_number_t threadCount = 0;
		kr = task_threads(task, &threads, &threadCount);
		if (kr == KERN_SUCCESS)
		{
			uint32_t cpuUsage = 0;
			for (uint i = 0; i < threadCount; i++)
			{
				struct thread_basic_info threadInfo;
				count = THREAD_BASIC_INFO_COUNT;
				kr = thread_info(threads[i], THREAD_BASIC_INFO, (thread_info_t)&threadInfo, &count);
				if (kr == KERN_SUCCESS)
				{
					cpuUsage += threadInfo.cpu_usage;
				}

				mach_port_deallocate(mach_task_self(), threads[i]);
			}

			vm_deallocate(mach_task_self(), (vm_address_t)threads, sizeof(*threads) * threadCount);

			[memoryInfo appendFormat:@"CPU usage: %u%%\n", cpuUsage];
			[memoryInfo appendFormat:@"Thread count: %u\n", threadCount];
		}
	}
	return memoryInfo;
}
%end
