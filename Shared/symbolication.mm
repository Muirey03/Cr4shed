@import Foundation;

#import <dlfcn.h>
#import <mach/mach.h>
#import "symbolication.h"

NSString* nameForRemoteSymbol(uint64_t addr, NSString* path, NSString* uuidStr, uint64_t imgAddr, CSArchitecture arch)
{
	NSString* name = nil;
	if (path.length && uuidStr.length && addr && imgAddr)
	{
		CFUUIDRef uuid = CFUUIDCreateFromString(kCFAllocatorDefault, (__bridge CFStringRef)uuidStr);
		if (uuid)
		{
			CSSymbolicatorRef symbolicator = CSSymbolicatorCreateWithURLAndArchitecture((__bridge CFURLRef)[NSURL fileURLWithPath:path], arch);
			if (!CSIsNull(symbolicator))
			{
				CSSymbolOwnerRef owner = CSSymbolicatorGetSymbolOwnerWithUUIDAtTime(symbolicator, uuid, kCSNow);
				if (!CSIsNull(owner))
				{
					uint64_t base = CSSymbolOwnerGetBaseAddress(owner);
					uint64_t symOffset = addr - imgAddr + base;
					CSSymbolRef symbol = CSSymbolOwnerGetSymbolWithAddress(owner, symOffset);
					if (!CSIsNull(symbol))
					{
						const char* c_name = CSSymbolGetName(symbol);
						if (c_name)
							name = [NSString stringWithUTF8String:c_name];
						else
							name = [NSString stringWithFormat:@"func_%llx", CSSymbolGetRange(symbol).location];
					}
				}
				CSRelease(symbolicator);
			}
			CFRelease(uuid);
		}
	}
	return name;
}

NSString* nameForLocalSymbol(NSNumber* addrNum, uint64_t* outOffset)
{
	NSString* name = nil;
	void* symAddr = (void*)[addrNum unsignedLongLongValue];
	Dl_info info = { NULL, NULL, NULL, NULL };
	int success = dladdr(symAddr, &info);
	if (symAddr && success)
	{
		CSSymbolicatorRef symbolicator = CSSymbolicatorCreateWithTask(mach_task_self());
		if (!CSIsNull(symbolicator))
		{
			CSSymbolOwnerRef owner = CSSymbolicatorGetSymbolOwnerWithAddressAtTime(symbolicator, (vm_address_t)symAddr, kCSNow);
			if (!CSIsNull(owner))
			{
				uint64_t imgAddr = (uint64_t)info.dli_fbase;
				if (outOffset) *outOffset = (uint64_t)symAddr - imgAddr;
				CSSymbolRef symbol = CSSymbolOwnerGetSymbolWithAddress(owner, (mach_vm_address_t)symAddr);
				if (!CSIsNull(symbol))
				{
					const char* c_name = CSSymbolGetName(symbol);
					if (c_name)
						name = [NSString stringWithUTF8String:c_name];
					else
						name = [NSString stringWithFormat:@"func_%llx", CSSymbolGetRange(symbol).location - imgAddr];
				}
			}
			CSRelease(symbolicator);
		}
	}
	return name;
}

NSArray* symbolicatedStackSymbols(NSArray* callStackSymbols, NSArray* callStackReturnAddresses)
{
	NSMutableArray* symArr = [callStackSymbols mutableCopy];
	for (uint32_t i = 0; i < callStackSymbols.count; i++)
	{
		uint64_t offset = 0;
		NSString* symName = nameForLocalSymbol(callStackReturnAddresses[i], &offset);
		if (symName && symName.length)
		{
			NSMutableArray<NSString*>* components = [[symArr[i] componentsSeparatedByString:@" "] mutableCopy];
			NSMutableArray<NSString*>* newComponents = [[NSMutableArray alloc] initWithCapacity:3];
			for (uint32_t b = 0; b < components.count; b++)
			{
				if (components[b].length)
				{
					[newComponents addObject:components[b]];
					if (newComponents.count >= 3)
						break;
				}
			}
			if (newComponents.count < 3)
				continue;
			NSString* newSym = [newComponents[0] stringByPaddingToLength:4 withString:@" " startingAtIndex:0];
			newSym = [newSym stringByAppendingString:newComponents[1]];
			newSym = [newSym stringByPaddingToLength:40 withString:@" " startingAtIndex:0];
			newSym = [newSym stringByAppendingString:newComponents[2]];
			NSUInteger padding = newSym.length + 30;
			newSym = [NSString stringWithFormat:@"%@ 0x%llx + 0x%llx", newSym, [callStackReturnAddresses[i] unsignedLongLongValue] - offset, offset];
			newSym = [newSym stringByPaddingToLength:padding withString:@" " startingAtIndex:0];
			if (symName)
				newSym = [newSym stringByAppendingFormat:@" // %@", symName];
			symArr[i] = newSym;
		}
	}
	return symArr;
}

NSArray* symbolicatedException(NSException* e)
{
	@autoreleasepool
	{
		NSArray* symArr = e.callStackSymbols;
		NSArray* addresses = e.callStackReturnAddresses;
		return symbolicatedStackSymbols(symArr, addresses);
	}
}
