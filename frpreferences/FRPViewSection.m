//
//  FRPViewSection.m
//  FRPreferences
//
//  Created by Fouad Raheb on 7/3/15.
//  Copyright (c) 2015 F0u4d. All rights reserved.
//

#import "FRPViewSection.h"

@implementation FRPViewSection

+ (instancetype)sectionWithHeight:(int)height initBlock:(FRPViewCellBlock)initBlock layoutBlock:(FRPViewCellBlock)layoutBlock {
    return [[self alloc] initWithHeight:height initBlock:initBlock layoutBlock:layoutBlock];
}

- (instancetype)initWithHeight:(int)height initBlock:(FRPViewCellBlock)initBlock layoutBlock:(FRPViewCellBlock)layoutBlock {
    FRPViewSection *section = [[super class] sectionWithTitle:nil footer:nil];
    FRPViewCell *cell = [FRPViewCell cellWithHeight:height
                                          initBlock:^(UITableViewCell *cell) {
                                              initBlock(cell);
                                          }
                                        layoutBlock:^(UITableViewCell *cell) {
                                            layoutBlock(cell);
                                          }];
    cell.hideSeperators = YES;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [section addCell:cell];
    return section;
}

@end
