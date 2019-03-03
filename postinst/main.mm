#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define oldPath @"/Library/MobileSubstrate/DynamicLibraries/Cr4shed.plist"
#define iOS12Path @"/Library/MobileSubstrate/DynamicLibraries/Cr4shed-iOS12.plist"
#define iOS11Path @"/Library/MobileSubstrate/DynamicLibraries/Cr4shed-iOS11.plist"

int main(int argc, char **argv, char **envp)
{
	if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"12.0"))
	{
		//delete cr4shed-ios11.plist
		[[NSFileManager defaultManager] removeItemAtPath:iOS11Path error:nil];
		//rename cr4shed.plist -> cr4shed-ios11.plist
		[[NSFileManager defaultManager] moveItemAtPath:oldPath toPath:iOS11Path error:nil];
		//rename cr4shed-ios12.plist -> cr4shed.plist
		[[NSFileManager defaultManager] moveItemAtPath:iOS12Path toPath:oldPath error:nil];
	}
	return 0;
}

// vim:ft=objc
