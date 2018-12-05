## Cr4shed
##### More useful crash logs at /var/mobile/error_log.log

This is a useful little package designed to help developers identify and fix crashes that have been reported to them by their users. It generates a crash log at `/var/mobile/error_log.log` including information such as the process that crashed, which unrecognised selector was attempted to be called, the method that the unrecognised selector was called from and the dylib the method that called the selector was created.

This is super useful if someone reports a crash to you and you can't work out what the issue is purely from the crash log. (Could also be useful for identifying causes of crashes in development). This report should be everything you need to work out exactly why the crash occured.

This is designed to work alongside CrashReporter, not to replace it. It provides information that CrashReporter cannot provide and is usually all you need to identify the cause of the crash, but CrashReporter can still prove useful too.
