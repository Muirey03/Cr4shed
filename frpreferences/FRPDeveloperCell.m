//
//  FRPDeveloperCell.m
//  FRPreferences
//
//  Created by Fouad Raheb on 7/3/15.
//  Copyright (c) 2015 F0u4d. All rights reserved.
//

#import "FRPDeveloperCell.h"

@interface FRPDeveloperCell ()
@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) UIImage *image;
@end

@implementation FRPDeveloperCell

+ (instancetype)cellWithTitle:(NSString *)title detail:(NSString *)detail image:(UIImage *)image url:(NSString *)url {
    return [[self alloc] cellWithTitle:title detail:detail image:image url:url];
}

- (instancetype)cellWithTitle:(NSString *)title detail:(NSString *)detail image:(UIImage *)image url:(NSString *)url {
    FRPDeveloperCell *cell = [super initWithTitle:title setting:nil];
    cell.url = url;
    cell.image = image;
    cell.detailTextLabel.text = detail;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    CGSize size = CGSizeMake(35,35);
    UIGraphicsBeginImageContextWithOptions(size, NO, UIScreen.mainScreen.scale);
    [self.image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *newThumbnail = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    cell.imageView.image = newThumbnail;;
    return cell;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.imageView.layer.cornerRadius = self.imageView.frame.size.width / 2;
    self.imageView.clipsToBounds = YES;
}

- (void)didSelectFromTable:(FRPreferences *)viewController {
    [viewController.tableView deselectRowAtIndexPath:[viewController.tableView indexPathForCell:self] animated:YES];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.url]];
}

@end
