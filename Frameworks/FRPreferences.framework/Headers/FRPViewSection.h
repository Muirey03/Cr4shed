//
//  FRPViewSection.h
//  FRPreferences
//
//  Created by Fouad Raheb on 7/3/15.
//  Copyright (c) 2015 F0u4d. All rights reserved.
//

#import "FRPViewCell.h"
#import "FRPSection.h"

@interface FRPViewSection : FRPSection

@property (nonatomic, copy) FRPViewCellBlock cellBlock;

+ (instancetype)sectionWithHeight:(int)height initBlock:(FRPViewCellBlock)initBlock layoutBlock:(FRPViewCellBlock)layoutBlock;

@end
