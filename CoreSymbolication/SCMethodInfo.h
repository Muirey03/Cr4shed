/**
 * Name: libsymbolicate
 * Type: iOS/OS X shared library
 * Desc: Library for symbolicating memory addresses.
 *
 * Author: Lance Fetters (aka. ashikase)
 * License: LGPL v3 (See LICENSE file for details)
 */

@interface SCMethodInfo : NSObject
@property(nonatomic, assign) uint64_t address;
@property(nonatomic, copy) NSString *name;
@end

CFComparisonResult reversedCompareMethodInfos(SCMethodInfo *a, SCMethodInfo *b);

/* vim: set ft=objcpp ff=unix sw=4 ts=4 tw=80 expandtab: */
