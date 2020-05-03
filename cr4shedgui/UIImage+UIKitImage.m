#import "UIImage+UIKitImage.h"

@implementation UIImage (UIKitImage)
+(UIImage*)uikitImageNamed:(NSString*)name
{
	NSString* artworkPath = @"/System/Library/PrivateFrameworks/UIKitCore.framework/Artwork.bundle";
	NSBundle* artworkBundle = [NSBundle bundleWithPath:artworkPath];
	if (!artworkBundle)
	{
		artworkPath = @"/System/Library/Frameworks/UIKit.framework/Artwork.bundle";
		artworkBundle = [NSBundle bundleWithPath:artworkPath];
	}
	UIImage* img = [UIImage imageNamed:name inBundle:artworkBundle];
	return [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

-(UIImage*)resizeToWidth:(CGFloat)newWidth
{
	CGFloat aspectRatio = self.size.height / self.size.width;
	CGSize newSize = CGSizeMake(newWidth, newWidth * aspectRatio);
	UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
	[self drawInRect:CGRectMake(0, 0, newWidth, newSize.height)];
	UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return newImage;
}

-(UIImage*)resizeToHeight:(CGFloat)newHeight
{
	CGFloat aspectRatio = self.size.width / self.size.height;
	CGSize newSize = CGSizeMake(newHeight * aspectRatio, newHeight);
	UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
	[self drawInRect:CGRectMake(0, 0, newSize.width, newHeight)];
	UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return newImage;
}
@end