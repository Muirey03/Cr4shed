/**
 * Name: libsymbolicate
 * Type: iOS/OS X shared library
 * Desc: Library for symbolicating memory addresses.
 *
 * Author: Lance Fetters (aka. ashikase)
 * License: LGPL v3 (See LICENSE file for details)
 */

#ifndef SYMBOLICATE_BINARY_H_
#define SYMBOLICATE_BINARY_H_

#include <mach/machine.h>

#ifdef __cplusplus
extern "C" {
#endif

BOOL offsetAndSizeOfBinaryInFile(const char *filepath, cpu_type_t cputype, cpu_subtype_t cpusubtype, off_t *offset, size_t *size);
BOOL isEncrypted(const char *filepath, cpu_type_t cputype, cpu_subtype_t cpusubtype);

#ifdef __cplusplus
}
#endif

#endif // SYMBOLICATE_BINARY_H_

/* vim: set ft=objcpp ff=unix sw=4 ts=4 tw=80 expandtab: */
