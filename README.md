## Cr4shed
##### A modern crash reporter for iOS

Cr4shed is a useful crash reporting package designed to help developers identify and fix crashes that have been reported to them by their users, and to help users identify the culprits of crashes. It generates a crash log in `/var/mobile/Library/Cr4shed` (accessible from the Cr4shed application) including information such as the process that crashed, the exact reason for the crash, the dylib that caused the crash and the entire call stack when the crash occurred.

This is extremely useful if someone reports a crash to you and you can't work out what the issue is purely from the system/CrashReporter crash log. (Is also extremely useful for identifying causes of crashes in development). This report should be everything you need to work out exactly why the crash occurred.

Cr4shed is now at the stage where it should be able to function as a full replacement for CrashReporter, but I cannot (yet) recommend uninstalling CrashReporter.