@import Foundation;

#import <stdlib.h>
#import <signal.h>
#import <uuid/uuid.h>
#import <mach/mach.h>
#import <substrate.h>
#import <symbolication.h>
#import <sharedutils.h>
#import "cr4shed_mach.h"
#import "mach_utils.h"
#import <rootless.h>

NSDictionary* getImageInfo(OSABinaryImageSegment* img)
{
	if ([img isKindOfClass:[NSDictionary class]])
		return (NSDictionary*)img;
	if ([img respondsToSelector:@selector(symbolInfo)]) {
		OSASymbolInfo* info = [img symbolInfo];
		return @{
			@"ExecutablePath" : info.path,
			@"StartAddress" : @(info.start)
		};
	}
	return nil;
}

%hook CrashReport
%property (nonatomic, assign) time_t crashTime;
%property (nonatomic, assign) uint64_t __far;
%property (nonatomic, assign) struct exception_info* exceptionInfo;
%property (nonatomic, assign) int realCrashedNumber;
%property (nonatomic, assign) BOOL hasBeenHandled;

-(instancetype)initWithTask:(mach_port_t)task exceptionType:(exception_type_t)exception thread:(mach_port_t)thread threadId:(NSUInteger)threadId threadStateFlavor:(int*)flavour threadState:(thread_state_t)old_state threadStateCount:(mach_msg_type_number_t)old_stateCnt
{
	if ((self = %orig))
	{
		[self cr4_sharedInitWithTask:task exceptionType:exception thread:thread threadStateFlavor:flavour threadState:old_state threadStateCount:old_stateCnt];
	}
	return self;
}

-(instancetype)initWithTask:(mach_port_t)task exceptionType:(exception_type_t)exception thread:(mach_port_t)thread threadStateFlavor:(int*)flavour threadState:(thread_state_t)old_state threadStateCount:(mach_msg_type_number_t)old_stateCnt
{
	if ((self = %orig))
	{
		[self cr4_sharedInitWithTask:task exceptionType:exception thread:thread threadStateFlavor:flavour threadState:old_state threadStateCount:old_stateCnt];
	}
	return self;
}

//does any work that must be done before the process dies
//namely, finding the correct crashed thread and state
%new
-(void)cr4_sharedInitWithTask:(mach_port_t)task exceptionType:(exception_type_t)exception thread:(mach_port_t)thread threadStateFlavor:(int*)flavour threadState:(thread_state_t)old_state threadStateCount:(mach_msg_type_number_t)old_stateCnt
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

	if (task != MACH_PORT_NULL) {
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
	}

	#define self ((CrashReport*)self)

	self.hasBeenHandled = task ? processHasBeenHandled(task) : NO;
	self.crashTime = crashTime;
	self.__far = CR4IvarExists(self, "_crashingAddress") ? CR4GetIvar<NSUInteger>(self, "_crashingAddress") : far;
	if (realThread == MACH_PORT_NULL)
		realThread = thread;

	if (task != MACH_PORT_NULL && realThread != MACH_PORT_NULL)
		self.realCrashedNumber = thread_number(task, realThread);
	else
		self.realCrashedNumber = -1;
	self.exceptionInfo = NULL;

	#undef self
}

%new
-(BOOL)cr4_isExceptionNonFatal
{
	#define self ((CrashReport*)self)

	if ([self respondsToSelector:@selector(isExceptionNonFatal)])
		return [self isExceptionNonFatal];
	return (!CR4GetIvar<void*>(self, "_exit_snapshot") && CR4GetIvar<mach_exception_data_t>(self, "_exceptionCode")[0] >> 58 != 10);

	#undef self
}

//responsible for gathering the exception info
-(void)loadBundleInfo
{
	#define self ((CrashReport*)self)
	%orig;

	//don't create report if cr4shed already generated an NSException report
	if (self.hasBeenHandled)
		return;

	//more work to fix ReportCrash's bug:
	exception_type_t exception = CR4GetIvar<exception_type_t>(self, "_exceptionType");
	mach_exception_data_t old_exception_codes = CR4GetIvar<mach_exception_data_t>(self, "_exceptionCode");
	mach_exception_data_t exception_codes = (mach_exception_data_t)calloc(2, sizeof(mach_exception_data_type_t));
	if (!exception_codes) return;
	mach_msg_type_number_t codeCnt = CR4GetIvar<mach_msg_type_number_t>(self, "_exceptionCodeCount");
	if (old_exception_codes)
		memcpy(exception_codes, old_exception_codes, codeCnt * sizeof(mach_exception_data_type_t));
	mach_port_t task = CR4GetIvar<mach_port_t>(self, "_task");
	int threadNum = CR4GetIvar<int>(self, "_crashedThreadNumber");
	int sig = CR4GetIvar<int>(self, "_signal");

	if (sig == 0 || sig == SIGKILL || isBlacklisted(self.procName))
		return;

	mach_exception_data_type_t subtype = 0;
	exception = mach_exception_type(sig, &subtype);
	exception_codes[0] = subtype;
	if (exception == EXC_CORPSE_NOTIFY && self.realCrashedNumber != -1)
	{
		exception_codes[1] = (mach_exception_data_type_t)self.__far;
		if (exception == EXC_BAD_ACCESS)
		{
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
		info->exception_type = mach_exception_string(exception, [self cr4_signalName:sig]);
		info->exception_subtype = mach_code_string(exception, exception_codes, codeCnt);
		info->exception_codes = mach_exception_codes_string(exception_codes, codeCnt);
		info->vm_info = mach_exception_vm_info(task, exception, exception_codes, codeCnt);
		info->thread_num = threadNum;

		if (CR4IvarExists(self, "_threadNames"))
		{
			NSArray* threadNames = CR4GetIvar<NSMutableArray*>(self, "_threadNames");
			info->thread_name = threadNames.count > threadNum ? threadNames[threadNum] : nil;
		}
		else if (CR4IvarExists(self, "_threadInfos"))
		{
			NSArray* threadInfos = CR4GetIvar<NSMutableArray*>(self, "_threadInfos");
			NSDictionary* infoDict = threadInfos.count > threadNum ? threadInfos[threadNum] : nil;
			info->thread_name = infoDict ?
				(infoDict[@"name"] ?: infoDict[@"queue"])
				: nil;
		}

		info->register_info = std::vector<struct register_info>();
		if (CR4IvarExists(self, "_threadState")) {
			_CR4_THREAD_STATE64 thread_state = CR4GetIvar<_CR4_THREAD_STATE64>(self, "_threadState");
			info->register_info = get_register_info(&thread_state);
		}

		//get annotation:
		NSString* libSwiftPath = nil;
		mach_vm_address_t staticAnnotationAddr = findSymbolInTask(task, "_gCRAnnotations", @"libswiftCore.dylib", &libSwiftPath);
		NSString* swiftErrorMessage = nil;
		if (staticAnnotationAddr && libSwiftPath.length)
		{
			NSArray* images = nil;
			if (CR4IvarExists(self, "_binaryImages"))
				images = CR4GetIvar<NSArray*>(self, "_binaryImages");
			else if (CR4IvarExists(self, "_taskImages"))
				images = CR4GetIvar<NSArray*>(self, "_binaryImages");

			mach_vm_address_t annotationAddr = 0;
			if (images)
			{
				for (OSABinaryImageSegment* img in images)
				{
					NSDictionary* imgInfo = getImageInfo(img);
					if ([imgInfo[@"ExecutablePath"] isEqualToString:libSwiftPath])
					{
						uint64_t start = [imgInfo[@"StartAddress"] unsignedLongLongValue];
						annotationAddr = staticAnnotationAddr + start;
						break;
					}
				}
			}

			if (annotationAddr)
			{
				mach_vm_address_t msgAddr = 0;
				rread(task, annotationAddr + offsetof(crashreporter_annotations_t, message), &msgAddr, sizeof(mach_vm_address_t));
				if (msgAddr)
				{
					if ([self respondsToSelector:@selector(_readStringAtTaskAddress:immutableOnly:maxLength:)])
						swiftErrorMessage = [self _readStringAtTaskAddress:msgAddr immutableOnly:NO maxLength:0];
					else if ([self respondsToSelector:@selector(_readStringAtTaskAddress:maxLength:immutableCheck:)])
						swiftErrorMessage = [self _readStringAtTaskAddress:msgAddr maxLength:0 immutableCheck:NO];

					if (swiftErrorMessage && [swiftErrorMessage hasSuffix:@"\n"])
						swiftErrorMessage = [swiftErrorMessage substringWithRange:NSMakeRange(0, swiftErrorMessage.length - 1)];
				}
			}
		}
		info->swiftErrorMessage = swiftErrorMessage;

		//get unsymbolicated backtrace:
		__block NSMutableArray* callStackSymbols = nil;
		__block NSInteger i = 0;
		if ([self respondsToSelector:@selector(decodeBacktraceWithBlock:)]) {
			[self decodeBacktraceWithBlock:^(NSInteger unused, NSArray* symbols){
				if (i++ == threadNum)
					callStackSymbols = [symbols mutableCopy];
			}];

			//symbolicate backtrace:
			if (CR4IvarExists(self, "_backtraces"))
			{
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
			}
		} else if (CR4IvarExists(self, "_threadInfos") && CR4IvarExists(self, "_usedImages")) {
			NSArray* threadInfos = CR4GetIvar<NSArray*>(self, "_threadInfos");
			NSArray* taskImages = CR4GetIvar<NSArray*>(self, "_usedImages");
			NSUInteger idx = threadNum < threadInfos.count ? threadNum : 0;
			NSArray* frames = threadInfos[idx][@"frames"];
			NSMutableArray* symbols = [NSMutableArray array];
			for (NSUInteger i = 0; i < frames.count; i++) {
				NSDictionary* frame = frames[i];
				NSDictionary* image = taskImages[[frame[@"imageIndex"] unsignedIntegerValue]];

				NSUInteger imgBase = [image[@"base"] unsignedIntegerValue];
				NSUInteger imgOffset = [frame[@"imageOffset"] unsignedIntegerValue];
				NSString* symName = frame[@"symbol"];

				#define P(s,l) s = [[s stringByPaddingToLength:l withString:@" " startingAtIndex:0] mutableCopy];
				NSMutableString* symbol = [NSMutableString stringWithFormat:@"%llu ", (unsigned long long)i]; P(symbol, 4);
				[symbol appendFormat:@"%@", image[@"name"]]; P(symbol, 40);
				[symbol appendFormat:@"0x%0.16llx ", (unsigned long long)(imgBase + imgOffset)];
				[symbol appendFormat:@"0x%llx + 0x%llx", (unsigned long long)imgBase, (unsigned long long)imgOffset]; P(symbol, 90);
				[symbol appendFormat:@"// %@", symName];
				[symbols addObject:symbol];
			}
			info->stackSymbols = symbols;
		}

		self.exceptionInfo = info;
		if (exception_codes)
			free((void*)exception_codes);
	}

	#undef self
}

//responsible for creating the report
%new
-(void)generateCr4shedReport
{
	#define self ((CrashReport*)self)

	if (self.hasBeenHandled)
		return;

	if (self.exceptionInfo)
	{
		struct exception_info* info = self.exceptionInfo;
		NSArray* images = nil;
		if (CR4IvarExists(self, "_binaryImages"))
			images = CR4GetIvar<NSArray*>(self, "_binaryImages");
		else if (CR4IvarExists(self, "_taskImages"))
			images = CR4GetIvar<NSArray*>(self, "_taskImages");

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
		if (!versionString.length && CR4IvarExists(self, "_bundle_vers"))
			versionString = CR4GetIvar<NSString*>(self, "_bundle_vers");
		if (!versionString.length && CR4IvarExists(self, "_bundle_info")) {
			NSDictionary* bundleInfo = CR4GetIvar<NSDictionary*>(self, "_bundle_info");
			versionString = [NSString stringWithFormat:@"%@", bundleInfo[@"CFBundleVersion"]];
		}
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
		if (info->register_info.size())
		{
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
		}

		//image infos:
		if (images)
		{
			[logStr appendString:@"\n\nLoaded images:\n"];
			NSUInteger imageCount = images.count;
			for (NSUInteger i = 0; i < imageCount; i++)
			{
				NSDictionary* imgInfo = getImageInfo((OSABinaryImageSegment*)images[i]);
				[logStr appendFormat:@"%llu: %@\n", (unsigned long long)i, imgInfo[@"ExecutablePath"]];
			}
		}

		 //extra info for the GUI to parse easily:
		NSDictionary* extraInfo = @{
			@"ProcessName" : info->processName ?: @"",
			@"ProcessBundleID" : info->bundleID ?: @"",
			@"Culprit" : culprit ?: @"Unknown"
		};
		logStr = [addInfoToLog(logStr, extraInfo) mutableCopy];

		// Create the dir if it doesn't exist already:
		NSString *path = ROOT_PATH_NS_VAR(@"/var/mobile/Library/Cr4shed");
		BOOL dirExists = [[NSFileManager defaultManager] fileExistsAtPath:path];
		if (!dirExists)
			dirExists = createDir(path);
		if (!dirExists) return; //should never happen, but just in case

		// Get the date to use for the filename:
		NSString* filenameDateStr = stringFromTime(crashTime, CR4DateFormatFilename);

		// Get the path for the new crash log:
		NSString *firstPath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@@%@.log", info->processName, filenameDateStr]];
		for (unsigned i = 1; [[NSFileManager defaultManager] fileExistsAtPath:firstPath]; i++)
			path = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@@%@ (%d).log", info->processName, filenameDateStr, i]];

		// Create the crash log
		writeStringToFile(logStr, path);

		//notification:
		NSString* notifContent = [NSString stringWithFormat:@"%@ crashed at %@", info->processName, dateString];
		NSDictionary* notifUserInfo = @{@"logPath" : path};
		showCr4shedNotification(notifContent, notifUserInfo);

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

	#undef self
}

-(void)generateLogAtLevel:(BOOL)arg1 withBlock:(id)arg2
{
	%orig;
	[(CrashReport*)self generateCr4shedReport];
}

-(void)generateCustomLogAtLevel:(BOOL)arg1 withBlock:(id)arg2
{
	%orig;
	[(CrashReport*)self generateCr4shedReport];
}

%new
-(NSString*)cr4_signalName:(int)sig
{
	if ([self respondsToSelector:@selector(signalName)])
		return [self signalName];
	if ([self respondsToSelector:@selector(decode_signal)])
		return [self decode_signal];
	return @"SIGNUNKN";
}
%end

%ctor
{
	Class crashReportCls = %c(CrashReport);
	int numClasses = objc_getClassList(NULL, 0);
	if (numClasses)
	{
		Class* classes = (Class*)malloc(sizeof(Class) * numClasses);
		numClasses = objc_getClassList(classes, numClasses);

		for (uint i = 0; i < numClasses; i++)
		{
			Class cls = classes[i];
			if (strcmp(class_getName(cls), "CrashReport") == 0)
			{
				NSBundle* bundle = [NSBundle bundleForClass:cls];
				if ([bundle.bundleIdentifier isEqualToString:@"com.apple.CrashReporter"])
				{
					crashReportCls = cls;
					break;
				}
			}
		}

		free((void*)classes);
	}

	if (!crashReportCls)
		crashReportCls = %c(OSACrashReport);

	%init(CrashReport = crashReportCls);
}
