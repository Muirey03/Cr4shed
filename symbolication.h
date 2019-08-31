#include "CoreSymbolication/CoreSymbolication.h"

NSString* nameForSymbol(NSNumber* addrNum);
NSArray* symbolicatedStackSymbols(NSArray* callStackSymbols, NSArray* callStackReturnAddresses);
NSArray* symbolicatedCallStack(NSException* e);