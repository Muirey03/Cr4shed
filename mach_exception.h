#ifdef __cplusplus
#include <vector>
#endif

#define EXC_UNIX_BAD_SYSCALL 0x10000
#define EXC_UNIX_BAD_PIPE 0x10001
#define EXC_UNIX_ABORT 0x10002
#define EXC_SOFT_SIGNAL 0x10003

struct register_info
{
	char* name;
	uint64_t value;
};

struct exception_info
{
	const char* exception_type;
	const char* exception_subtype;
	const char* vm_info;
	uint64_t thread_id;
	char* thread_name;
	const char* thread_label;
	char* exception_codes;
	std::vector<struct register_info> register_info;
	NSArray* stackSymbols;
	NSArray* returnAddresses;
};

typedef void (*mry_exception_handler_t)(struct exception_info*);

extern mach_port_t exc_port;
extern dispatch_queue_t exception_queue;
extern mry_exception_handler_t exception_handler;

void setMachExceptionHandler(mry_exception_handler_t excHandler);