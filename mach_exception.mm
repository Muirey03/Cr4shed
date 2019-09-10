@import Foundation;

#import "mach_exception.h"
#include <mach/mach.h>
#include <string.h>
#include <stdbool.h>
#include <substrate.h>

mach_port_t exc_port;
dispatch_queue_t exception_queue;
mry_exception_handler_t exception_handler;

extern "C" {
boolean_t exc_server(mach_msg_header_t *InHeadP, mach_msg_header_t *OutHeadP);
}

typedef struct
{
	__uint64_t    __x[29];	/* General purpose registers x0-x28 */
	__uint64_t    __fp;		/* Frame pointer x29 */
	__uint64_t    __lr;		/* Link register x30 */
	__uint64_t    __sp;		/* Stack pointer x31 */
	__uint64_t    __pc;		/* Program counter */
	__uint32_t    __cpsr;	/* Current program status register */
	__uint32_t    __pad;    /* Same size for 32-bit or 64-bit clients */
} _CR4_THREAD_STATE64;

static const char* mach_exception_string(exception_type_t exception)
{
	#define exc_case(type) case type: return #type
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
			return "EXC_UNKNOWN";
	}
	#undef exc_case
}

static const char* mach_code_string(exception_type_t type, mach_exception_data_t codes, mach_msg_type_number_t codeCnt)
{
	if (codeCnt < 1)
		return NULL;
	
	mach_exception_code_t code = codes[0];
	mach_exception_subcode_t subcode = codeCnt > 1 ? codes[1] : 0;
	const char* code_str = NULL;

	//get code string if applicable:
	#define set_code(code_type) if (code == code_type) code_str = #code_type
	switch (type)
	{
		case EXC_BAD_ACCESS:
			set_code(KERN_INVALID_ADDRESS);
			set_code(KERN_PROTECTION_FAILURE);
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
		size_t str_size = snprintf(NULL, 0, "%s: %p", code_str, (void*)subcode);
		str = (char*)malloc(str_size + 1);
		snprintf(str, str_size + 1, "%s: %p", code_str, (void*)subcode);
	}
	else
	{
		size_t str_size = snprintf(NULL, 0, "%p", (void*)subcode);
		str = (char*)malloc(str_size + 1);
		snprintf(str, str_size + 1, "%p", (void*)subcode);
	}
	return str;
}

static char* mach_exception_codes_string(mach_exception_data_t codes, mach_msg_type_number_t codeCnt)
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

static vm_prot_t vm_region_get_protection(vm_address_t address)
{
	vm_address_t addr = address;
	vm_size_t size = 0;
	vm_region_basic_info_data_64_t info = { 0 };
	mach_msg_type_number_t info_count = VM_REGION_BASIC_INFO_COUNT_64;
	mach_port_t vm_obj;
	vm_region_64(mach_task_self(), &addr, &size, VM_REGION_BASIC_INFO_64, (vm_region_info_t)&info, &info_count, &vm_obj);
	return info.protection;
}

static const char* mach_exception_vm_info(exception_type_t type, mach_exception_data_t codes, mach_msg_type_number_t codeCnt)
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
			vm_prot_t prot = vm_region_get_protection(addr);
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

static uint64_t thread_identifier(mach_port_t thread)
{
	thread_act_port_array_t threads;
	mach_msg_type_number_t thread_count;
	task_threads(mach_task_self(), &threads, &thread_count);
	for (unsigned int i = 0; i < thread_count; i++)
	{
		if (threads[i] == thread)
			return i;
	}
	return 7009;
}

static char* thread_name(mach_port_t thread)
{
	thread_extended_info_data_t info = { 0 };
	mach_msg_type_number_t count = THREAD_EXTENDED_INFO_COUNT;
	thread_info(thread, THREAD_EXTENDED_INFO, (thread_info_t)&info, &count);
	if (info.pth_name[0] == '\0')
		return NULL;
	return strdup(info.pth_name);
}

static const char* thread_dispatch_label(mach_port_t thread)
{
	thread_identifier_info_data_t info = { 0 };
	mach_msg_type_number_t count = THREAD_IDENTIFIER_INFO_COUNT;
	kern_return_t kr = thread_info(thread, THREAD_IDENTIFIER_INFO, (thread_info_t)&info, &count);
	if (kr == KERN_SUCCESS)
	{
		dispatch_queue_t queue = (__bridge dispatch_queue_t)(void*)*(uint64_t*)info.dispatch_qaddr;
		if (queue)
			return dispatch_queue_get_label(queue);
	}
	return NULL;
}

static std::vector<struct register_info> get_register_info(mach_port_t thread)
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

typedef struct {
    uint64_t previous;
    uint64_t return_address;
} mach_stack_frame_entry;

static bool is_valid_address(uint64_t address)
{
	if (address == 0)
		return false;
	uint8_t tmp_byte = 0;
	vm_size_t copied = 0;
	kern_return_t kr = vm_read_overwrite(mach_task_self(), (vm_address_t)address, (vm_size_t)sizeof(uint8_t), (vm_address_t)&tmp_byte, &copied);
	return kr == KERN_SUCCESS && copied;
}

void thread_call_stack(mach_port_t thread, NSArray** outStackSymbols, NSArray** outReturnAddresses)
{
	if (!outStackSymbols && !outReturnAddresses)
		return;

	NSMutableArray* stackSymbols = nil;
	NSMutableArray* returnAddresses = [NSMutableArray new];

	//get thread state:
	_CR4_THREAD_STATE64 thread_state = {{ 0 }};
	mach_msg_type_number_t thread_stateCnt = ARM_THREAD_STATE64_COUNT;
	thread_get_state(thread, ARM_THREAD_STATE64, (thread_state_t)&thread_state, &thread_stateCnt);

	uint64_t pc_reg = thread_state.__pc;
	[returnAddresses addObject:@(pc_reg)];
	uint64_t link_reg = thread_state.__lr;
	if (link_reg != pc_reg)
		[returnAddresses addObject:@(link_reg)];
	uint64_t frame_addr = thread_state.__fp;
	if (!is_valid_address(frame_addr))
		return;
	mach_stack_frame_entry frame = { 0 };
	memcpy(&frame, (void*)frame_addr, sizeof(mach_stack_frame_entry));
	[returnAddresses addObject:@(frame.return_address)];
	do
	{
		memcpy(&frame, (void*)frame.previous, sizeof(mach_stack_frame_entry));
		[returnAddresses addObject:@(frame.return_address)];
	} while (is_valid_address(frame.previous));

	NSUInteger stackCount = returnAddresses.count;
	if (!stackCount)
		return;
	stackSymbols = [[NSMutableArray alloc] initWithCapacity:stackCount];

	NSUInteger columnWidths[3] = { 8, 32, 24 };

	for (unsigned int i = 0; i < stackCount; i++)
	{
		//get address info:
		void* ret_addr = (void*)[returnAddresses[i] unsignedIntegerValue];
		Dl_info info = { 0 };
		dladdr(ret_addr, &info);
		
		//format string:
		NSString* symbolStr;
		
		//number:
		symbolStr = [NSString stringWithFormat:@"%u", i];
		symbolStr = [symbolStr stringByPaddingToLength:columnWidths[0] withString:@" " startingAtIndex:0];

		//image name:
		NSString* imageName = [[NSString stringWithFormat:@"%s", info.dli_fname] lastPathComponent];
		symbolStr = [symbolStr stringByAppendingFormat:@"%@", imageName];
		symbolStr = [symbolStr stringByPaddingToLength:columnWidths[0] + columnWidths[1] withString:@" " startingAtIndex:0];

		//return address:
		symbolStr = [symbolStr stringByAppendingFormat:@"0x%016llx", (uint64_t)ret_addr];
		symbolStr = [symbolStr stringByPaddingToLength:columnWidths[0] + columnWidths[1] + columnWidths[2] withString:@" " startingAtIndex:0];

		//symbol name:
		symbolStr = [symbolStr stringByAppendingFormat:@"// %s", info.dli_sname];

		[stackSymbols addObject:symbolStr];
	}

	if (outReturnAddresses)
		*outReturnAddresses = returnAddresses;
	if (outStackSymbols)
		*outStackSymbols = stackSymbols;
}

extern "C" kern_return_t catch_exception_raise_state_identity(
	mach_port_t             exception_port,
	mach_port_t             thread,
	mach_port_t             task,
	exception_type_t        exception,
	exception_data_t  		code,
	mach_msg_type_number_t  codeCnt,
	int*                    flavor,
	thread_state_t          old_state,
	mach_msg_type_number_t  old_stateCnt,
	thread_state_t          new_state,
	mach_msg_type_number_t *new_stateCnt
)
{
	_STRUCT_ARM_EXCEPTION_STATE64 exception_state = *(_STRUCT_ARM_EXCEPTION_STATE64*)old_state;
	mach_exception_data_type_t exception_codes[2] = { (mach_exception_data_type_t)(code[0]), (mach_exception_data_type_t)exception_state.__far };
	if (exception_port == exc_port && exception_handler)
	{
		struct exception_info info;
		memset((void*)&info, 0, sizeof(struct exception_info));

		info.exception_type = mach_exception_string(exception);
		info.exception_subtype = mach_code_string(exception, exception_codes, codeCnt);
		info.exception_codes = mach_exception_codes_string(exception_codes, codeCnt);
		info.vm_info = mach_exception_vm_info(exception, exception_codes, codeCnt);
		info.thread_id = thread_identifier(thread);
		info.thread_name = thread_name(thread);
		info.thread_label = thread_dispatch_label(thread);
		info.register_info = get_register_info(thread);
		NSArray* callStack = nil;
		NSArray* returnAddresses = nil;
		thread_call_stack(thread, &callStack, &returnAddresses);
		info.stackSymbols = callStack;
		info.returnAddresses = returnAddresses;

		(*exception_handler)(&info);

		if (info.exception_subtype)
			free((void*)info.exception_subtype);
		if (info.exception_codes)
			free(info.exception_codes);
		if (info.vm_info)
			free((void*)info.vm_info);
		if (info.thread_name)
			free(info.thread_name);
		for (struct register_info reg_info : info.register_info)
		{
			if (reg_info.name)
				free(reg_info.name);
		}
	}
	return KERN_SUCCESS;
}

void setMachExceptionHandler(mry_exception_handler_t excHandler)
{
	exception_handler = excHandler;
	exception_queue = dispatch_queue_create("com.muirey03.cr4shed-exception_queue", NULL);
	dispatch_async(exception_queue, ^{
		kern_return_t kr;

		//old exception ports:
		exception_mask_t old_masks[16];
		mach_msg_type_number_t old_masksCnt = 0;
		exception_handler_t old_handlers[16];
		exception_behavior_t old_behaviors[16];
		thread_state_flavor_t old_flavors[16];
		memset(old_handlers, 0, sizeof(exception_handler_t) * 16);

		//create exception port:
		exc_port = MACH_PORT_NULL;
		kr = mach_port_allocate(mach_task_self(), MACH_PORT_RIGHT_RECEIVE, &exc_port);
		if (kr != KERN_SUCCESS || exc_port == MACH_PORT_NULL)
			goto failure;
		kr = mach_port_insert_right(mach_task_self(), exc_port, exc_port, MACH_MSG_TYPE_MAKE_SEND);
		if (kr != KERN_SUCCESS)
			goto failure;

		//set new exception port:
		kr = task_swap_exception_ports(mach_task_self(), EXC_MASK_ALL, exc_port, EXCEPTION_STATE_IDENTITY, ARM_EXCEPTION_STATE64, old_masks, &old_masksCnt, old_handlers, old_behaviors, old_flavors);
		if (kr != KERN_SUCCESS)
			goto failure;

		mach_msg_return_t mr;
		struct {
			mach_msg_header_t head;
			char data[256];
		} reply;
		struct msg_struct {
			mach_msg_header_t head;
			mach_msg_body_t msgh_body;
			uint8_t data[1024];
		} msg;

		//wait for exception message:
		mr = mach_msg(&msg.head, MACH_RCV_MSG|MACH_RCV_LARGE, 0, sizeof(msg), exc_port, MACH_MSG_TIMEOUT_NONE, MACH_PORT_NULL);
		//cache the message in case exc_server fucks with it
		struct msg_struct old_msg = msg;

		//handle exception:
		if (!exc_server(&msg.head, &reply.head))
		{
			memcpy(&reply, &msg, sizeof(reply));
		}

		//message old ports:
		old_msg.head.msgh_local_port = MACH_PORT_NULL;
		for (unsigned int i = 0; i < old_masksCnt; i++)
		{
			msg.head.msgh_remote_port = old_handlers[i];
			mach_msg(&old_msg.head, MACH_SEND_MSG, old_msg.head.msgh_size, 0, MACH_PORT_NULL, MACH_MSG_TIMEOUT_NONE, MACH_PORT_NULL);
		}

		//send reply:
		mr = mach_msg(&reply.head, MACH_SEND_MSG, reply.head.msgh_size, 0, MACH_PORT_NULL, MACH_MSG_TIMEOUT_NONE, MACH_PORT_NULL);
		if (mr != MACH_MSG_SUCCESS)
			goto failure;

	failure:
		if (exc_port != MACH_PORT_NULL)
			mach_port_deallocate(mach_task_self(), exc_port);
		exc_port = MACH_PORT_NULL;
	});
}