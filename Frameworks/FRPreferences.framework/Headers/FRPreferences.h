//
//  FRPPreferences.h
//  FRPreferences
//
//  Created by Fouad Raheb on 7/2/15.
//  Copyright (c) 2015 F0u4d. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FRPreferences : UITableViewController

@property (nonatomic, strong) NSArray *sections;
@property (nonatomic, strong) NSString *plistPath;

+ (instancetype)tableWithSections:(NSArray *)sections title:(NSString *)title tintColor:(UIColor *)color;

@end