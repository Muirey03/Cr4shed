#import <Foundation/Foundation.h>
#import <mach/mach.h>

#define CR4ProcsNeedRefreshNotificationName @"com.muirey03.cr4shed-procsNeedRefresh"
#define CR4BlacklistDidChangeNotificationName @"com.muirey03.cr4shed-blacklistDidChange"
#define kSortingMethod @"SortingMethod"
#define kProcessBlacklist @"ProcessBlacklist"
#define kEnableJetsam @"EnableJetsam"

typedef NS_ENUM(NSInteger, CR4DateFormat)
{
	CR4DateFormatPretty,
	CR4DateFormatTimeOnly,
	CR4DateFormatFilename
};

#ifdef __cplusplus
extern "C" {
#endif
NSString* getImage(NSString* symbol);
NSString* determineCulprit(NSArray* symbols);
NSString* stringFromDate(NSDate* date, CR4DateFormat type);
NSString* deviceVersion();
NSString* deviceName();
size_t rread(mach_port_t task, mach_vm_address_t where, void* p, size_t size);
size_t rwrite(mach_port_t task, mach_vm_address_t where, const void* p, size_t size);
char* rread_string(mach_port_t task, vm_address_t addr);
uint64_t rread64(mach_port_t task, mach_vm_address_t where);
uint32_t rread32(mach_port_t task, mach_vm_address_t where);
mach_vm_address_t taskGetImageInfos(mach_port_t task);
void markProcessAsHandled(void);
bool processHasBeenHandled(mach_port_t task);
@class HBPreferences;
HBPreferences* sharedPreferences(void);
@class NSString;
@class NSDictionary;
NSString* addInfoToLog(NSString* logContents, NSDictionary* info);
NSDictionary* getInfoFromLog(NSString* logContents);
#ifdef __cplusplus
}

bool isBlacklisted(NSString* procName = nil);
bool wantsLogJetsam();
void lazyLoadBundle(NSString* const bundlePath);
void showCr4shedNotification(NSString* notifContent, NSDictionary* notifUserInfo);
#endif
