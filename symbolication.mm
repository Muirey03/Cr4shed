@import Foundation;

#import "MobileGestalt/MobileGestalt.h"
#include <mach-o/dyld.h>
#include <dlfcn.h>
#include <mach-o/loader.h>
#import "symbolication.h"

inline CSArchitecture getArch(const char* path)
{
    CSArchitecture arch;
    uint32_t count = _dyld_image_count();
    const struct mach_header* header = NULL;
    if (path)
    {
        for (int i = 0; i < count; i++)
        {
            if (strcmp(_dyld_get_image_name(i), path) == 0)
            {
                header = _dyld_get_image_header(i);
                break;
            }
        }
    }
    if (header)
    {
        arch.cpu_type = header->cputype;
        arch.cpu_subtype = header->cpusubtype;
    }
    else
    {
        arch = CSArchitectureGetCurrent();
    }
    return arch;
}

static NSString* executableUUID(const char* path)
{
    if (!path)
        return nil;

    const struct mach_header *executableHeader = NULL;
    for (int i = 0; i < _dyld_image_count(); i++)
    {
        if (strcmp(path, _dyld_get_image_name(i)) == 0)
        {
            executableHeader = _dyld_get_image_header(i);
            break;
        }
    }

    if (!executableHeader)
        return nil;

    BOOL is64bit = executableHeader->magic == MH_MAGIC_64 || executableHeader->magic == MH_CIGAM_64;
    uintptr_t cursor = (uintptr_t)executableHeader + (is64bit ? sizeof(struct mach_header_64) : sizeof(struct mach_header));
    const struct segment_command *segmentCommand = NULL;
    for (uint32_t i = 0; i < executableHeader->ncmds; i++, cursor += segmentCommand->cmdsize)
    {
        segmentCommand = (struct segment_command *)cursor;
        if (segmentCommand->cmd == LC_UUID)
        {
            const struct uuid_command *uuidCommand = (const struct uuid_command *)segmentCommand;
            NSString* uuidStr = [[[NSUUID alloc] initWithUUIDBytes:uuidCommand->uuid] UUIDString];
            return uuidStr;
        }
    }

    return nil;
}

// NOTE: CFUUIDCreateFromString() does not support unhyphenated UUID strings.
//       UUID must be hyphenated, must follow pattern "8-4-4-4-12".
static CFUUIDRef CFUUIDCreateFromUnformattedCString(const char* uuidStr) {
    CFUUIDRef uuid = NULL;
    if (strlen(uuidStr) >= 32) {
        CFStringRef stringRef = CFStringCreateWithCString(kCFAllocatorDefault, uuidStr, kCFStringEncodingASCII);
        if (stringRef != NULL) {
            uuid = CFUUIDCreateFromString(kCFAllocatorDefault, stringRef);
            CFRelease(stringRef);
        }
    }
    return uuid;
}

static CSSymbolicatorRef symbolicator(const char* path, CSArchitecture* archp = NULL)
{
    CSArchitecture arch = archp ? *archp : getArch(path);

    if (arch.cpu_type != 0)
    {
        CSSymbolicatorRef symb = CSSymbolicatorCreateWithPathAndArchitecture(path, arch);
        if (!CSIsNull(symb))
        {
            return symb;
        }
    }
    return kCSNull;
}

static CSSymbolOwnerRef ownerForPath(const char* path)
{
    if (path)
    {
        NSString* uuidStr = executableUUID(path);
        CSSymbolicatorRef sym = symbolicator(path);
        if (!CSIsNull(sym))
        {
            CFUUIDRef uuid = CFUUIDCreateFromUnformattedCString([uuidStr UTF8String]);
            if (uuid)
            {
                CSSymbolOwnerRef owner = CSSymbolicatorGetSymbolOwnerWithUUIDAtTime(sym, uuid, kCSNow);
                CFRelease(uuid);
                if (!CSIsNull(owner))
                    return owner;
            }
        }
    }
    return kCSNull;
}

static CSSymbolOwnerRef ownerForPathAndUUID(const char* path, NSString* uuidStr, CSArchitecture arch)
{
    if (arch.cpu_type == 0)
        arch = CSArchitectureGetCurrent();
    CSSymbolicatorRef sym = symbolicator(path, &arch);
    if (!CSIsNull(sym))
    {
        CFUUIDRef uuid = CFUUIDCreateFromUnformattedCString([uuidStr UTF8String]);
        if (uuid)
        {
            CSSymbolOwnerRef owner = CSSymbolicatorGetSymbolOwnerWithUUIDAtTime(sym, uuid, kCSNow);
            CFRelease(uuid);
            if (!CSIsNull(owner))
                return owner;
        }
    }
    return kCSNull;
}

NSString* nameForSymbolOffsetInImage(uint64_t addr, const char* path, NSString* uuidStr, uint64_t imgAddr, CSArchitecture arch)
{
    if (uuidStr.length == 36 && strlen(path) && addr && imgAddr)
    {
        CSSymbolOwnerRef owner = ownerForPathAndUUID(path, uuidStr, arch);
        if (!CSIsNull(owner))
        {
            uint64_t base = CSSymbolOwnerGetBaseAddress(owner);
            uint64_t symOffset = addr + base - imgAddr;
            CSSymbolRef symbol = CSSymbolOwnerGetSymbolWithAddress(owner, symOffset);
            if (!CSIsNull(symbol))
            {
                const char* c_name = CSSymbolGetName(symbol);
                if (c_name)
                    return [NSString stringWithUTF8String:c_name];
            }
        }
    }
    return nil;
}

NSString* nameForSymbol(NSNumber* addrNum, uint64_t* outOffset)
{
    void* addrPtr = (void*)[addrNum integerValue];
    Dl_info info = { NULL, NULL, NULL, NULL };
    int success = dladdr(addrPtr, &info);
    if (success)
    {
        void* symAddr = info.dli_saddr;
        const char* path = info.dli_fname;
        if (path)
        {
            CSSymbolOwnerRef owner = ownerForPath(path);
            if (!CSIsNull(owner))
            {
                uint64_t base = CSSymbolOwnerGetBaseAddress(owner);
                uint64_t imgAddr = (uint64_t)info.dli_fbase;
                uint64_t symOffset = (uint64_t)symAddr + base - imgAddr;
                if (outOffset) *outOffset = (uint64_t)addrPtr - imgAddr;
                CSSymbolRef symbol = CSSymbolOwnerGetSymbolWithAddress(owner, symOffset);
                if (!CSIsNull(symbol))
                {
                    return [NSString stringWithUTF8String:CSSymbolGetName(symbol)];
                }
            }
        }
    }
    return nil;
}

NSArray* symbolicatedStackSymbols(NSArray* callStackSymbols, NSArray* callStackReturnAddresses)
{
    NSMutableArray* symArr = [callStackSymbols mutableCopy];
    for (int i = 0; i < callStackSymbols.count; i++)
    {
        uint64_t offset = 0;
        NSString* symName = nameForSymbol(callStackReturnAddresses[i], &offset);
        if (symName)
        {
            NSMutableArray* components = [[symArr[i] componentsSeparatedByString:@" "] mutableCopy];
            for (int b = 0; b < 3; b++)
            {
                [components removeObjectAtIndex:(components.count - 1)];
            }
            NSString* newSym = [components componentsJoinedByString:@" "];
            NSUInteger padding = newSym.length + 30;
            newSym = [NSString stringWithFormat:@"%@ 0x%llx + 0x%llx", newSym, [callStackReturnAddresses[i] unsignedLongLongValue] - offset, offset];
            newSym = [newSym stringByPaddingToLength:padding withString:@" " startingAtIndex:0];
            newSym = [newSym stringByAppendingFormat:@" // %@", symName];
            symArr[i] = newSym;
        }
    }
    return [symArr copy];
}

NSArray* symbolicatedCallStack(NSException* e)
{
    NSArray* symArr = e.callStackSymbols;
    NSArray* addresses = e.callStackReturnAddresses;
    return symbolicatedStackSymbols(symArr, addresses);
}
