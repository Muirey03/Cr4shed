#include <vector>
#include <time.h>

struct exception_info
{
	NSString* processName;
	NSString* bundleID;
	NSString* exception_type;
	const char* exception_subtype;
	const char* vm_info;
	uint64_t thread_num;
	NSString* thread_name;
	char* exception_codes;
	std::vector<struct register_info> register_info;
	NSArray* stackSymbols;
};

@interface NSObject (Private)
-(NSString*)_methodDescription;
@end

@interface CrashReport : NSObject
@property (nonatomic, retain) NSString* procName;
//%new properties
@property (nonatomic, assign) time_t crashTime;
@property (nonatomic, assign) uint64_t __far;
@property (nonatomic, assign) struct exception_info* exceptionInfo;
@property (nonatomic, assign) mach_port_t realThread;
@property (nonatomic, assign) int realCrashedNumber;
-(BOOL)isExceptionNonFatal;
-(BOOL)cr4_isExceptionNonFatal;
-(NSString*)signalName;
-(NSArray*)binaryImages;
-(void)decodeBacktraceWithBlock:(void(^)(NSInteger, id))arg1;
-(NSDictionary*)binaryImageDictionaryForAddress:(uint64_t)addr;
-(void)generateCr4shedReport;
@end