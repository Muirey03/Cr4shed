#include <mach/mach.h>
#include <vector>
#import <objc/runtime.h>
#import <sharedutils.h>
#include <time.h>

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

struct register_info
{
	char* name;
	uint64_t value;
};

struct crashreporter_annotations_t
{
	uint64_t version;
	char* message;
	uint64_t signature_string;
	uint64_t backtrace;
	char* message2;
	uint64_t thread;
	uint64_t dialog_mode;
	uint64_t abort_cause;
};

NSString* mach_exception_string(exception_type_t exception, NSString* signalName);
const char* mach_code_string(exception_type_t type, mach_exception_data_t codes, mach_msg_type_number_t codeCnt);
char* mach_exception_codes_string(mach_exception_data_t codes, mach_msg_type_number_t codeCnt);
vm_prot_t vm_region_get_protection(mach_port_t task, vm_address_t address);
const char* mach_exception_vm_info(mach_port_t task, exception_type_t type, mach_exception_data_t codes, mach_msg_type_number_t codeCnt);
std::vector<struct register_info> get_register_info(mach_port_t thread);
uint64_t thread_number(mach_port_t task, mach_port_t thread);
exception_type_t mach_exception_type(int sig, mach_exception_data_type_t* exception_subtype);
void freeThreadArray(thread_act_port_array_t threads, mach_msg_type_number_t thread_count);
BOOL createDir(NSString* path);
void writeStringToFile(NSString* str, NSString* path);
NSString* stringFromTime(time_t time, CR4DateFormat type);
mach_vm_address_t findSymbolInTask(mach_port_t task, const char* symbolName, NSString* lastPathComponent, NSString** imageName);
template <typename Type>
static inline Type CR4GetIvar(id self, const char* name)
{
	Ivar ivar = class_getInstanceVariable(object_getClass(self), name);
	if (ivar == NULL)
		@throw [NSException exceptionWithName:@"IvarNotFoundException" reason:[NSString stringWithFormat:@"Unable to find Ivar with name: \"%s\". THIS IS A BUG IN CR4SHED. Please send this report to @Muirey03 on Twitter.", name] userInfo:nil];

#if __has_feature(objc_arc)
	void* pointer = ivar == NULL ? NULL : reinterpret_cast<char*>((__bridge void*)self) + ivar_getOffset(ivar);
#else
	void* pointer = ivar == NULL ? NULL : reinterpret_cast<char*>(self) + ivar_getOffset(ivar);
#endif
	return *reinterpret_cast<Type*>(pointer);
}
