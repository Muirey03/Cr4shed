/**
 * Name: libsymbolicate
 * Type: iOS/OS X shared library
 * Desc: Library for symbolicating memory addresses.
 *
 * Author: Lance Fetters (aka. ashikase)
 * License: LGPL v3 (See LICENSE file for details)
 */

#ifndef SYMBOLICATE_LOCALSYMBOLS_H_
#define SYMBOLICATE_LOCALSYMBOLS_H_

#ifdef __cplusplus
extern "C" {
#endif

uint64_t offsetOfDylibInSharedCache(const char *sharedCachePath, const char *filepath);
const char *nameForLocalSymbol(const char *sharedCachePath, uint64_t dylibOffset, uint64_t symbolAddress);

#ifdef __cplusplus
}
#endif

#endif // SYMBOLICATE_LOCALSYMBOLS_H_

/* vim: set ft=objcpp ff=unix sw=4 ts=4 tw=80 expandtab: */
