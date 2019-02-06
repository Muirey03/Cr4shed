## Cr4shed
##### More useful crash logs at /var/tmp/crash_logs

This is a useful little package designed to help developers identify and fix crashes that have been reported to them by their users. It generates a crash log in `/var/tmp/crash_logs` including information such as the process that crashed, the exact reason for the crash, the method that the crash occurred in and the dylib that caused the crash.

This is super useful if someone reports a crash to you and you can't work out what the issue is purely from the crash log. (Is also extremely useful for identifying causes of crashes in development). This report should be everything you need to work out exactly why the crash occurred.

This is designed to work alongside CrashReporter, not to replace it. It provides information that CrashReporter cannot provide and is usually all you need to identify the cause of the crash, but CrashReporter can still prove useful too.
