#import <CoreSymbolication/CoreSymbolication.h>

NSString* nameForLocalSymbol(NSNumber* addrNum, uint64_t* outOffset);
NSArray* symbolicatedStackSymbols(NSArray* callStackSymbols, NSArray* callStackReturnAddresses);
NSArray* symbolicatedException(NSException* e);
NSString* nameForRemoteSymbol(uint64_t addr, NSString* path, NSString* uuidStr, uint64_t imgAddr, CSArchitecture arch);
