//
//  FRPSection.m
//  FRPreferences
//
//  Created by Fouad Raheb on 7/2/15.
//  Copyright (c) 2015 F0u4d. All rights reserved.
//

#import "FRPSection.h"

@interface FRPSection ()

@end


@implementation FRPSection

+ (instancetype)sectionWithTitle:(NSString *)title footer:(NSString *)footer {
    return [[self alloc] initWithTitle:title footer:footer];
}

- (instancetype)initWithTitle:(NSString *)title footer:(NSString *)footer {
    if (self = [super init]) {
        self.headerTitle = title;
        self.footerTitle = footer;
        self.cells = [NSMutableArray new];
    }
    
    return self;
}

- (void)addCell:(UITableViewCell *)cell {
    [self.cells addObject:cell];
}

- (void)addCells:(NSArray *)cells {
    [self.cells addObjectsFromArray:cells];
}

@end