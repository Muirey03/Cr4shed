#import <vector>
#import <time.h>

struct exception_info
{
	NSString* processName;
	NSString* bundleID;
	NSString* exception_type;
	NSString* swiftErrorMessage;
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

@interface CrashReport : NSObject // fixme
@property (nonatomic, retain) NSString* procName;
//%new properties
@property (nonatomic, assign) time_t crashTime;
@property (nonatomic, assign) uint64_t __far;
@property (nonatomic, assign) struct exception_info* exceptionInfo;
@property (nonatomic, assign) int realCrashedNumber;
@property (nonatomic, assign) BOOL hasBeenHandled;
-(void)cr4_sharedInitWithTask:(mach_port_t)task exceptionType:(exception_type_t)exception thread:(mach_port_t)thread threadStateFlavor:(int*)flavour threadState:(thread_state_t)old_state threadStateCount:(mach_msg_type_number_t)old_stateCnt;
-(BOOL)isExceptionNonFatal;
-(BOOL)cr4_isExceptionNonFatal;
-(NSString*)signalName;
-(NSString*)cr4_signalName:(int)sig;
-(NSArray*)binaryImages;
-(void)decodeBacktraceWithBlock:(void(^)(NSInteger, id))arg1;
-(NSDictionary*)binaryImageDictionaryForAddress:(uint64_t)addr;
-(void)generateCr4shedReport;
-(NSString*)_readStringAtTaskAddress:(mach_vm_address_t)addr immutableOnly:(BOOL)imut maxLength:(NSUInteger)maxLen;
-(NSString*)_readStringAtTaskAddress:(mach_vm_address_t)addr maxLength:(NSUInteger)maxLen immutableCheck:(BOOL)imut;
-(NSString*)decode_signal;
@end

@interface OSASymbolInfo : NSObject
@property (readonly) NSString* path;
@property (assign) NSUInteger start;
@property (assign) NSUInteger size;
@end

@interface OSABinaryImageSegment : NSObject
-(OSASymbolInfo*)symbolInfo;
@end
