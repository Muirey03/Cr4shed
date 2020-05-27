@import CoreFoundation;
@import Foundation;

#import "mach_utils.h"
#import "symbolication.h"
#include <stdlib.h>
#include <string.h>
#include <MRYIPCCenter.h>

#define EXC_UNIX_BAD_SYSCALL 0x10000
#define EXC_UNIX_BAD_PIPE 0x10001
#define EXC_UNIX_ABORT 0x10002
#define EXC_SOFT_SIGNAL 0x10003

NSString* mach_exception_string(exception_type_t exception, NSString* signalName)
{
	#define exc_case(type) case type: return [NSString stringWithFormat:@"%s (%@)", #type, signalName]
	switch (exception)
	{
		exc_case(EXC_BAD_ACCESS);
		exc_case(EXC_BAD_INSTRUCTION);
		exc_case(EXC_ARITHMETIC);
		exc_case(EXC_EMULATION);
		exc_case(EXC_SOFTWARE);
		exc_case(EXC_BREAKPOINT);
		exc_case(EXC_SYSCALL);
		exc_case(EXC_MACH_SYSCALL);
		exc_case(EXC_RPC_ALERT);
		exc_case(EXC_CRASH);
		exc_case(EXC_RESOURCE);
		exc_case(EXC_GUARD);
		exc_case(EXC_CORPSE_NOTIFY);
		default:
			return @"EXC_UNKNOWN";
	}
	#undef exc_case
}

const char* mach_code_string(exception_type_t type, mach_exception_data_t codes, mach_msg_type_number_t codeCnt)
{
	if (codeCnt < 1)
		return NULL;
	
	mach_exception_code_t code = codes[0];
	mach_exception_subcode_t subcode = codeCnt > 1 ? codes[1] : 0;
	const char* code_str = NULL;
	bool has_subcode = false;

	//get code string if applicable:
	#define set_code(code_type) if (code == code_type) code_str = #code_type
	switch (type)
	{
		case EXC_BAD_ACCESS:
			set_code(KERN_INVALID_ADDRESS);
			set_code(KERN_PROTECTION_FAILURE);
			has_subcode = true;
			break;
		case EXC_SOFTWARE:
			set_code(EXC_UNIX_BAD_SYSCALL);
			set_code(EXC_UNIX_BAD_PIPE);
			set_code(EXC_UNIX_ABORT);
			set_code(EXC_SOFT_SIGNAL);
	}
	#undef set_code

	//format string:
	char* str = NULL;
	if (code_str)
	{
		if (has_subcode)
		{
			size_t str_size = snprintf(NULL, 0, "%s: %p", code_str, (void*)subcode);
			str = (char*)malloc(str_size + 1);
			snprintf(str, str_size + 1, "%s: %p", code_str, (void*)subcode);
		}
		else
		{
			size_t str_size = snprintf(NULL, 0, "%s", code_str);
			str = (char*)malloc(str_size + 1);
			snprintf(str, str_size + 1, "%s", code_str);
		}
	}
	return str;
}

char* mach_exception_codes_string(mach_exception_data_t codes, mach_msg_type_number_t codeCnt)
{
	char* str = NULL;
	for (unsigned int i = 0; i < codeCnt; i++)
	{
		if (str)
		{
			size_t new_sz = snprintf(NULL, 0, "%s, 0x%016llx", str, codes[i]) + 1;
			char* tmp_str = (char*)malloc(new_sz);
			snprintf(tmp_str, new_sz, "%s, 0x%016llx", str, codes[i]);
			free(str);
			str = tmp_str;
		}
		else
		{
			size_t new_sz = snprintf(NULL, 0, "0x%016llx", codes[i]) + 1;
			str = (char*)malloc(new_sz);
			snprintf(str, new_sz, "0x%016llx", codes[i]);
		}
	}
	return str;
}

vm_prot_t vm_region_get_protection(mach_port_t task, vm_address_t address)
{
	vm_address_t addr = address;
	vm_size_t size = 0;
	vm_region_basic_info_data_64_t info = { 0 };
	mach_msg_type_number_t info_count = VM_REGION_BASIC_INFO_COUNT_64;
	mach_port_t vm_obj;
	vm_region_64(task, &addr, &size, VM_REGION_BASIC_INFO_64, (vm_region_info_t)&info, &info_count, &vm_obj);
	return info.protection;
}

const char* mach_exception_vm_info(mach_port_t task, exception_type_t type, mach_exception_data_t codes, mach_msg_type_number_t codeCnt)
{	
	char* str = NULL;
	if (codeCnt > 1 && type == EXC_BAD_ACCESS)
	{
		mach_exception_subcode_t addr = codes[1];
		if (codes[0] == KERN_INVALID_ADDRESS)
		{
			const char* fmt = "%p is not in any region.";
			size_t str_size = snprintf(NULL, 0, fmt, addr);
			str = (char*)malloc(str_size + 1);
			snprintf(str, str_size + 1, fmt, addr);
		}
		else
		{
			//format protection string:
			vm_prot_t prot = vm_region_get_protection(task, addr);
			char rwx_str[4];
			strcpy(rwx_str, "---");
			if (prot & VM_PROT_READ)
				rwx_str[0] = 'r';
			if (prot & VM_PROT_WRITE)
				rwx_str[1] = 'w';
			if (prot & VM_PROT_EXECUTE)
				rwx_str[2] = 'x';
			
			str = strdup(rwx_str);
		}
	}
	return str;
}

std::vector<struct register_info> get_register_info(mach_port_t thread)
{
	std::vector<struct register_info> info_vec;

	//get thread state:
	_CR4_THREAD_STATE64 thread_state = {{ 0 }};
	mach_msg_type_number_t thread_stateCnt = ARM_THREAD_STATE64_COUNT;
	thread_get_state(thread, ARM_THREAD_STATE64, (thread_state_t)&thread_state, &thread_stateCnt);

	#define ADD_INFO(reg, name) do { \
		struct register_info info = { strdup(name), thread_state.__##reg }; \
		info_vec.push_back(info); \
	} while (false)

	ADD_INFO(pc, "PC");
	ADD_INFO(lr, "LR");
	ADD_INFO(cpsr, "CPSR");

	#define ARM64_REGISTER_COUNT 29
	for (unsigned int i = 0; i < ARM64_REGISTER_COUNT; i++)
	{
		size_t reg_name_size = snprintf(NULL, 0, "x%d", i) + 1;
		char* reg_name = (char*)malloc(reg_name_size);
		snprintf(reg_name, reg_name_size, "x%d", i);
		ADD_INFO(x[i], reg_name);
		free(reg_name);
	}

	return info_vec;
}

static uint64_t	thread_get_id(mach_port_t thread)
{
	thread_identifier_info_data_t identifier_info = {0};
	mach_msg_type_number_t count = THREAD_IDENTIFIER_INFO_COUNT;
	kern_return_t kr = thread_info(thread, THREAD_IDENTIFIER_INFO, (thread_info_t)&identifier_info, &count);
	if (kr != KERN_SUCCESS)
		return 0;
	return identifier_info.thread_id;
}

uint64_t thread_number(mach_port_t task, mach_port_t thread)
{
	uint64_t desired_id = thread_get_id(thread);
	thread_act_port_array_t threads;
	mach_msg_type_number_t thread_count;
	task_threads(task, &threads, &thread_count);
	for (unsigned int i = 0; i < thread_count; i++)
	{
		uint64_t tid = thread_get_id(threads[i]);
		if (tid == desired_id)
			return i;
	}
	freeThreadArray(threads, thread_count);
	return 0;
}

exception_type_t mach_exception_type(int sig, mach_exception_data_type_t* exception_subtype)
{
	exception_type_t type = 0;
	exception_data_type_t subtype = 0;
	switch (sig)
	{
		case SIGSEGV:
			type = EXC_BAD_ACCESS;
			subtype = KERN_INVALID_ADDRESS;
			break;
		case SIGBUS:
			type = EXC_BAD_ACCESS;
			subtype = KERN_PROTECTION_FAILURE;
			break;
		case SIGILL:
			type = EXC_BAD_INSTRUCTION;
			break;
		case SIGFPE:
			type = EXC_ARITHMETIC;
			break;
		case SIGEMT:
			type = EXC_EMULATION;
			break;
		case SIGSYS:
			type = EXC_SOFTWARE;
			subtype = EXC_UNIX_BAD_SYSCALL;
			break;
		case SIGPIPE:
			type = EXC_SOFTWARE;
			subtype = EXC_UNIX_BAD_PIPE;
			break;
		case SIGABRT:
			type = EXC_SOFTWARE;
			subtype = EXC_UNIX_ABORT;
			break;
		case SIGKILL:
			type = EXC_SOFTWARE;
			subtype = EXC_SOFT_SIGNAL;
			break;
		case SIGTRAP:
			type = EXC_BREAKPOINT;
			break;
	}
	if (exception_subtype)
		*exception_subtype = subtype;
	return type;
}

void freeThreadArray(thread_act_port_array_t threads, mach_msg_type_number_t thread_count)
{
	if (threads && thread_count)
		vm_deallocate(mach_task_self(), (vm_address_t)threads, sizeof(thread_act_port_t) * thread_count);
}

BOOL createDir(NSString* path)
{
	NSDictionary<NSFileAttributeKey, id>* attributes = @{
		NSFilePosixPermissions : @0755,
		NSFileOwnerAccountName : @"mobile",
		NSFileGroupOwnerAccountName : @"mobile"
	};
	return [[NSFileManager defaultManager] createDirectoryAtURL:[NSURL fileURLWithPath:path] withIntermediateDirectories:YES attributes:attributes error:nil];
}

void writeStringToFile(NSString* str, NSString* path)
{
	NSFileManager* manager = [NSFileManager defaultManager];
	if ([manager fileExistsAtPath:path])
		[manager removeItemAtPath:path error:NULL];
	NSDictionary<NSFileAttributeKey, id>* attributes = @{
		NSFilePosixPermissions : @0666,
		NSFileOwnerAccountName : @"mobile",
		NSFileGroupOwnerAccountName : @"mobile"
	};
	NSData* contentsData = [str dataUsingEncoding:NSUTF8StringEncoding];
	[manager createFileAtPath:path contents:contentsData attributes:attributes];
}

NSString* stringFromTime(time_t t, CR4DateFormat type)
{
	if (!t) t = time(NULL);
	MRYIPCCenter* ipcCenter = [MRYIPCCenter centerNamed:@"com.muirey03.cr4sheddserver"];
	NSDictionary* reply = [ipcCenter callExternalMethod:@selector(stringFromTime:) withArguments:@{@"time" : @(t), @"type" : @(type)}];
	NSString* str = reply[@"ret"];
	//fallback if cr4shedd is not available or failed for whatever reason
	if (!str)
	{
		NSDate* date = [NSDate dateWithTimeIntervalSince1970:t];
		str = stringFromDate(date, type);
	}
	return str;
}

mach_vm_address_t findSymbolInTask(mach_port_t task, const char* symbolName, NSString* lastPathComponent, NSString** imageName)
{
	CSSymbolicatorRef symbolicator = CSSymbolicatorCreateWithTask(task);
	if (CSIsNull(symbolicator))
		return 0;
	
	__block mach_vm_address_t addr = 0;
	__block NSString* imagePath = nil;
	CSSymbolicatorForeachSymbolAtTime(symbolicator, kCSNow, ^int(CSSymbolRef symbol){
		if (!CSIsNull(symbol))
		{
			const char* name = CSSymbolGetMangledName(symbol);
			if (name && symbolName)
			{
				if (strcmp(name, symbolName) == 0)
				{
					mach_vm_address_t symAddr = CSSymbolGetRange(symbol).location;
					CSSymbolOwnerRef owner = CSSymbolGetSymbolOwner(symbol);
					if (!CSIsNull(owner))
					{
						const char* c_path = CSSymbolOwnerGetPath(owner);
						NSString* path = c_path ? @(c_path) : nil;
						if ([path.lastPathComponent isEqualToString:lastPathComponent])
						{
							addr = symAddr - CSSymbolOwnerGetBaseAddress(owner);
							imagePath = path;
							return 0;
						}
					}
				}
			}
		}
		return 1;
	});
	CSRelease(symbolicator);
	if (imageName)
		*imageName = imagePath;
	return addr;
}
