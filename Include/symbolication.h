#import <CoreSymbolication/CoreSymbolication.h>

NSString* nameForSymbol(NSNumber* addrNum, uint64_t* outOffset);
NSArray* symbolicatedStackSymbols(NSArray* callStackSymbols, NSArray* callStackReturnAddresses);
NSArray* symbolicatedCallStack(NSException* e);
NSString* nameForSymbolOffsetInImage(uint64_t addr, const char* path, NSString* uuidStr, uint64_t imgAddr, CSArchitecture arch);
