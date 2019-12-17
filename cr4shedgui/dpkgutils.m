#import "dpkgutils.h"

NSString* outputOfCommand(NSString* cmd, NSArray<NSString*>* args)
{
	NSTask* task = [NSTask new];
	task.executableURL = [NSURL fileURLWithPath:cmd];
	task.arguments = args;

	NSPipe* p = [NSPipe pipe];
	task.standardOutput = p;

	[task launch];
	[task waitUntilExit];

	NSFileHandle* handle = [p fileHandleForReading];
	NSData* data = [handle readDataToEndOfFile];
	return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

NSString* packageForFile(NSString* file)
{
	if (file)
	{
		NSArray<NSString*>* args = @[@"-S", file];
		NSString* ret = outputOfCommand(@"/usr/bin/dpkg-query", args);
		ret = [ret stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		NSArray<NSString*>* comp = [ret componentsSeparatedByString:@":"];
		NSString* package = comp.count ? comp[0] : nil;
		return package.length ? package : nil;
	}
	return nil;
}

NSString* controlFieldForPackage(NSString* package, NSString* field)
{
	if (package && field)
	{
		NSString* format = [NSString stringWithFormat:@"-f=\'${%@}\'", field];
		NSArray<NSString*>* args = @[@"-W", format, package];
		NSString* ret = outputOfCommand(@"/usr/bin/dpkg-query", args);
		ret = [ret stringByReplacingOccurrencesOfString:@"\'" withString:@""];
		return ret.length ? ret : nil;
	}
	return nil;
}
