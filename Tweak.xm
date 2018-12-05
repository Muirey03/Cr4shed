%hook UIResponder
-(void)doesNotRecognizeSelector:(SEL)selector
{
    @try
    {
        %orig;
    }
    @catch (NSException* e)
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
        lastSymbol = [lastSymbol stringByReplacingCharactersInRange:NSMakeRange(startI, endI - startI) withString:@" - "];

        NSString* currentProcess = [NSBundle mainBundle].bundleIdentifier;
        NSString* errorMessage = [NSString stringWithFormat:@"%@: %@ crashed with error message: %@ in method: \'%@\'", [NSDate date], currentProcess, e.reason, lastSymbol];

        NSString* path = @"/var/mobile/error_log.log";
        NSString* oldContent = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
        NSString* newContent = [oldContent stringByAppendingString:[NSString stringWithFormat:@"\n%@", errorMessage]];
        [(oldContent.length ? newContent : errorMessage) writeToFile:path atomically:NO encoding:NSUTF8StringEncoding error:nil];

        %orig;
    }
}
%end
