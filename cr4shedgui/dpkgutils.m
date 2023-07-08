#import "dpkgutils.h"
#import <rootless.h>
#import <spawn.h>

extern char **environ;

// https://stackoverflow.com/a/13065080
char **getArray(NSArray *arr)
{
	unsigned count = [arr count];
	char **array = (char **)malloc((count + 1) * sizeof(char*));
	for (unsigned i = 0; i < count; i++)
	{
		array[i] = strdup([[arr objectAtIndex:i] UTF8String]);
	}
	array[count] = NULL;
	return array;
}

void freeArray(char **array)
{
	if (array != NULL)
	{
		for (unsigned index = 0; array[index] != NULL; index++)
		{
			free(array[index]);
		}
		free(array);
	}
}

NSString* outputOfCommand(NSString* cmd, NSArray<NSString*>* args)
{
	// Sanity check
	if (strstr(getenv("PATH"), "/var/jb") == NULL) {
		// https://github.com/opa334/Dopamine/blob/1595dbf05561e55aa36e8dd39a77ebe2a5dd00c1/Packages/Fugu15KernelExploit/Sources/Fugu15KernelExploit/oobPCI.swift#L252
		setenv("PATH", "/sbin:/bin:/usr/sbin:/usr/bin:/var/jb/sbin:/var/jb/bin:/var/jb/usr/sbin:/var/jb/usr/bin", 1);
	}

	int out[2];
	if (pipe(out) != 0)
		return nil;

	posix_spawn_file_actions_t action;
	posix_spawn_file_actions_init(&action);
	posix_spawn_file_actions_adddup2(&action, out[1], STDOUT_FILENO);
	posix_spawn_file_actions_addclose(&action, out[0]);

	pid_t pid;
	char **cArgs = getArray(args);
	posix_spawn(&pid, [cmd UTF8String], &action, NULL, cArgs, environ);
	close(out[1]);
	waitpid(pid, NULL, 0);

	const size_t buffSize = PIPE_BUF;
	char buff[buffSize];
	ssize_t rBytes;
	while (( rBytes = read(out[0], buff, buffSize )) > 0)
	{
		rBytes = read(out[0], buff, buffSize);
	}

	if (rBytes == -1)
	   return nil;

	posix_spawn_file_actions_destroy(&action);
	freeArray(cArgs);

	return [NSString stringWithUTF8String:buff];
}

NSString* packageForFile(NSString* file)
{
	if (file)
	{
		NSArray<NSString*>* args = @[@"-S", file];
		NSString* ret = outputOfCommand(ROOT_PATH_NS_VAR(@"/usr/bin/dpkg-query"), args);
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
		NSString* ret = outputOfCommand(ROOT_PATH_NS_VAR(@"/usr/bin/dpkg-query"), args);
		ret = [ret stringByReplacingOccurrencesOfString:@"\'" withString:@""];
		return ret.length ? ret : nil;
	}
	return nil;
}
