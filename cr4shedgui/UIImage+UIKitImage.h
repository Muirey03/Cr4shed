@interface UIImage (Private)
+(UIImage*)imageNamed:(NSString*)name inBundle:(NSBundle*)bundle;
@end

@interface UIImage (UIKitImage)
+(UIImage*)uikitImageNamed:(NSString*)name;
-(UIImage*)resizeToWidth:(CGFloat)newWidth;
-(UIImage*)resizeToHeight:(CGFloat)newHeight;
@end