//
//  FRSliderCellTableViewCell.h
//  FRPreferences
//
//  Created by Fouad Raheb on 6/14/15.
//  Copyright (c) 2015 F0u4d. All rights reserved.
//

#import "FRPCell.h"

typedef void (^FRPSliderCellChanged)(UISlider *sender);

@interface FRPSliderCell : FRPCell

@property (nonatomic, strong) UISlider *sliderCell;
@property (nonatomic, strong) UILabel *lLabel;
@property (nonatomic, strong) UILabel *rLabel;
@property (nonatomic, strong) UILabel *cLabel;
@property (nonatomic, strong) UILabel *vLabel;

@property (nonatomic) float min;
@property (nonatomic) float max;

+ (instancetype)cellWithTitle:(NSString *)title setting:(FRPSettings *)setting min:(float)min max:(float)max postNotification:(NSString *)notification changeBlock:(FRPSliderCellChanged)block;

@end
