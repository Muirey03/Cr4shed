//
//  FRPCell.m
//  FRPreferences
//
//  Created by Fouad Raheb on 7/2/15.
//  Copyright (c) 2015 F0u4d. All rights reserved.
//

#import "FRPCell.h"

@implementation FRPCell

+ (instancetype)cellWithTitle:(NSString *)title setting:(FRPSettings *)setting {
    return [[self alloc] initWithTitle:title setting:setting];
}

- (instancetype)initWithTitle:(NSString *)title setting:(FRPSettings *)setting {
    if (self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil]) {
        self.clipsToBounds = YES;
        self.textLabel.text = title;
        self.setting = setting;
    }
    return self;
}

- (void)didSelectFromTable:(FRPreferences *)viewController {
//    NSIndexPath *indexPath = [viewController.tableView indexPathForCell:self];
//    NSLog(@"Did Select Cell At Index: %@",indexPath);
}

@end
