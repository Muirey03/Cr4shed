@import Foundation;
#include <malloc/malloc.h>
#include <vector>
#import <sharedutils.h>
#import <MRYIPCCenter.h>
#import "../cr4shedmach/mach_utils.h"
#import "cr4shed_jetsam.h"

#define ISA_MASK 0x0000000ffffffff8ULL
#define ISA_MAGIC_MASK 0x000003f000000001ULL
#define ISA_MAGIC_VALUE 0x000001a000000001ULL

static NSString* serverWriteStringToFile(NSString* str, NSString* filename)
{
	MRYIPCCenter* ipcCenter = [MRYIPCCenter centerNamed:@"com.muirey03.cr4sheddserver"];
	NSDictionary* reply = [ipcCenter callExternalMethod:@selector(writeString:) withArguments:@{@"string" : str, @"filename" : filename}];
	return reply[@"path"];
}

char* classNameForClass(mach_port_t task, vm_address_t clsAddr)
{
	vm_address_t classRWAddr = rread64(task, clsAddr + 0x20) & 0x7FFFFFFFFFF8;
	if (!classRWAddr)
		return NULL;

	vm_address_t ro_or_rw_ext = rread64(task, classRWAddr + 8);
	uintptr_t tag = ro_or_rw_ext & 1;

	vm_address_t classROAddr = ro_or_rw_ext;
	if (tag == 1)
	{
		vm_address_t classRWExtAddr = ro_or_rw_ext & ~1;
		if (!classRWExtAddr)
			return NULL;
		classROAddr = rread64(task, classRWExtAddr);
	}
	if (!classROAddr)
		return NULL;
	
	vm_address_t nameAddr = rread64(task, classROAddr + 0x18);
	return rread_string(task, nameAddr);
}

%hook MemoryResourceException
-(BOOL)extractCorpseInfo
{
	BOOL ret = %orig;
	[self extractBacktraceInfo];
	[self generateCr4shedReport];
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
																@"Uptime: %llds\n"
																@"Reason: %@\n",
																dateString,
																self.execName,
																self.bundleID,
																device,
																(long long)self.upTime,
																reason];

	[logStr appendFormat:@"\nClass info:\n%@", [self fetchClassInfo]];
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
-(NSString*)fetchClassInfo
{
	mach_port_t task = self.task;

	static std::vector<void*> needFree;
	memory_reader_t* reader = [](task_t task, vm_address_t address, vm_size_t size, void** ptr){
		void* local = malloc(size);
		needFree.push_back(local);
		rread(task, address, local, size);
		*ptr = local;
		return 0;
	};
	auto cleanup = [](void){
		for (void* buffer : needFree)
			free(buffer);
		needFree.clear();
	};

	static NSMutableDictionary* objectMap;
	objectMap = [NSMutableDictionary new];
	vm_range_recorder_t* recorder = [](task_t task, void *context, unsigned type, vm_range_t *ranges, unsigned rangeCount){
		for (unsigned i = 0; i < rangeCount; i++)
		{
			vm_range_t range = ranges[i];
			vm_address_t potentialObj = range.address;
			uint64_t isa = rread64(task, potentialObj + offsetof(struct objc_object, isa));
			if ((isa & 0xFFFF800000000000) == 0 && (isa & ISA_MAGIC_MASK) == ISA_MAGIC_VALUE && (isa & ISA_MASK) != 0)
			{
				vm_address_t cls = isa & ISA_MASK;
				objectMap[@(cls)] = @([objectMap[@(cls)] unsignedLongLongValue] + 1);
			}
		}
	};

	unsigned zoneCount = 0;
	vm_address_t* zones;
	kern_return_t kr = malloc_get_all_zones(task, reader, &zones, &zoneCount);
	if (kr == KERN_SUCCESS)
	{
		for (unsigned i = 0; i < zoneCount; i++)
		{
			vm_address_t zone = zones[i];
			vm_address_t zone_name_addr = rread64(task, zone + offsetof(malloc_zone_t, zone_name));
			char* zone_name = NULL;
			if (zone_name_addr)
				zone_name = rread_string(task, zone_name_addr);
			
			//only inspect DefaultMallocZone
			if (!zone_name || strcmp(zone_name, "DefaultMallocZone") != 0)
				continue;

			vm_address_t introspect = rread64(task, zone + offsetof(malloc_zone_t, introspect));
			kern_return_t(*enumerator)(task_t, void*, unsigned, vm_address_t, memory_reader_t, vm_range_recorder_t);
			enumerator = (__typeof enumerator)rread64(task, introspect + offsetof(malloc_introspection_t, enumerator));
			if (enumerator)
				enumerator(task, (void*)zone_name, MALLOC_PTR_IN_USE_RANGE_TYPE, zone, reader, recorder);
			
			if (zone_name)
				free((void*)zone_name);
			break;
		}
	}

	//free memory allocated by `reader`
	cleanup();

	NSMutableString* classInfo = [NSMutableString new];
	NSArray* sortedClasses = [objectMap.allKeys sortedArrayUsingComparator:^(id obj1, id obj2) {
		NSUInteger n = [objectMap[obj1] unsignedIntegerValue];
		NSUInteger m = [objectMap[obj2] unsignedIntegerValue];
		return [@(m) compare:@(n)];
	}];
	for (uint32_t i = 0; i < sortedClasses.count && i < 20; i++)
	{
		vm_address_t clsAddr = [sortedClasses[i] unsignedLongLongValue];
		char* clsName = classNameForClass(task, clsAddr);	

		if (clsName && strlen(clsName))
			[classInfo appendFormat:@"%s [%llu]\n", clsName, [objectMap[sortedClasses[i]] unsignedLongLongValue]];
		
		if (clsName)
			free((void*)clsName);
	}
	return classInfo;
}
%end
