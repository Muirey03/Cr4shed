#import <rocketbootstrap/rocketbootstrap.h>

%ctor
{
	@autoreleasepool
	{
		rocketbootstrap_unlock("com.muirey03.cr4sheddserver");
	}
}
