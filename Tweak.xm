@import ObjectiveC.objc_exception; //contains objc_exception_throw

/* Gets the parent symbol of the crash (essentially the method that caused the crash): */
static NSString* getLastSymbol()
{
    NSString* lastSymbol = [NSThread callStackSymbols][3];
    lastSymbol = [lastSymbol substringWithRange:NSMakeRange(4, lastSymbol.length - 4)];

    int startI = 0;
    int endI = 0;
    for (int i = 0; i < lastSymbol.length; i++)
    {
        char c = [lastSymbol characterAtIndex:i];
        if (c == ' ')
        {
            if (!startI)
            {
                startI = i;
            }
        }
        else
        {
            if (startI)
            {
                endI = i;
                break;
            }
        }
    }
    return [lastSymbol stringByReplacingCharactersInRange:NSMakeRange(startI, endI - startI) withString:@" - "];
}

static void createCrashLog(NSException* e)
{
    // Format the contents of the new crahs log:
    NSString* lastSymbol = getLastSymbol();
    NSString* currentProcess = [NSBundle mainBundle].bundleIdentifier;
    NSString* errorMessage = [NSString stringWithFormat:@"Date: %@\n"
                                                        @"Bundle id: %@\n"
                                                        @"Exception type: %@\n"
                                                        @"Reason: %@\n"
                                                        @"Parent symbol: %@",
                                                        [NSDate date],
                                                        currentProcess,
                                                        e.name,
                                                        e.reason,
                                                        lastSymbol];

    // Create the dir if it doesn't exist already:
    BOOL isDir;
    BOOL dirExists = [[NSFileManager defaultManager] fileExistsAtPath:@"/var/tmp/crash_logs" isDirectory:&isDir];
    if (!dirExists)
        isDir = [[NSFileManager defaultManager] createDirectoryAtURL:[NSURL fileURLWithPath:@"/var/tmp/crash_logs"] withIntermediateDirectories:YES attributes:nil error:nil];
    if (!isDir) return; //should never happen, but just in case

    // Get the date to use for the filename:
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd_HH:mm"];
    NSString* dateStr = [formatter stringFromDate:[NSDate date]];

    // Get the path for the new crash log:
    NSString* path = [NSString stringWithFormat:@"/var/tmp/crash_logs/%@.log", dateStr];
    for (int i = 1; [[NSFileManager defaultManager] fileExistsAtPath:path]; i++)
        path = [NSString stringWithFormat:@"/var/tmp/crash_logs/%@ (%d).log", dateStr, i];

    // Create the crash log
    [errorMessage writeToFile:path atomically:NO encoding:NSUTF8StringEncoding error:nil];
}

// Called everytime a NSException is thrown
%hookf (void, objc_exception_throw, NSException* e)
{
    createCrashLog(e);
    %orig;
}
