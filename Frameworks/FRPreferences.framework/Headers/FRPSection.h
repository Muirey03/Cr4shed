//
//  FRPSection.h
//  FRPreferences
//
//  Created by Fouad Raheb on 7/2/15.
//  Copyright (c) 2015 F0u4d. All rights reserved.
//


#import <UIKit/UIKit.h>

@interface FRPSection : UITableViewCell

@property (nonatomic, strong) NSString *headerTitle;
@property (nonatomic, strong) NSString *footerTitle;

@property (nonatomic, strong) NSMutableArray *cells;

@property (nonatomic, strong) UIColor *tintUIColor;

+ (instancetype)sectionWithTitle:(NSString *)title footer:(NSString *)footer;

- (void)addCell:(UITableViewCell *)cell;
- (void)addCells:(NSArray *)cells;

@end