/**
 * Name: libsymbolicate
 * Type: iOS/OS X shared library
 * Desc: Library for symbolicating memory addresses.
 *
 * Author: Lance Fetters (aka. ashikase)
 * License: LGPL v3 (See LICENSE file for details)
 */

#import <Foundation/Foundation.h>

#include "Headers.h"

@class SCSymbolInfo;

@interface SCBinaryInfo : NSObject
@property(nonatomic, readonly) uint64_t address;
@property(nonatomic, readonly) NSString *architecture;
@property(nonatomic, readonly) uint64_t baseAddress;
@property(nonatomic, readonly, getter = isEncrypted) BOOL encrypted;
@property(nonatomic, readonly, getter = isExecutable) BOOL executable;
@property(nonatomic, readonly, getter = isFromSharedCache) BOOL fromSharedCache;
@property(nonatomic, readonly) NSArray *methods;
@property(nonatomic, readonly) NSString *path;
@property(nonatomic, readonly) NSString *uuid;
@property(nonatomic, readonly) int64_t slide;
@property(nonatomic, readonly) NSArray *symbolAddresses;
- (id)initWithPath:(NSString *)path address:(uint64_t)address architecture:(NSString *)architecture uuid:(NSString *)uuid;
- (SCSymbolInfo *)sourceInfoForAddress:(uint64_t)address;
- (SCSymbolInfo *)symbolInfoForAddress:(uint64_t)address;
@end

/* vim: set ft=objcpp ff=unix sw=4 ts=4 tw=80 expandtab: */
