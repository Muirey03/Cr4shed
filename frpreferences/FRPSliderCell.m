//
//  FRSliderCellTableViewCell.m
//  FRPreferences
//
//  Created by Fouad Raheb on 6/14/15.
//  Copyright (c) 2015 F0u4d. All rights reserved.
//

#import "FRPSliderCell.h"

@implementation FRPSliderCell

+ (instancetype)cellWithTitle:(NSString *)title setting:(FRPSettings *)setting min:(float)min max:(float)max postNotification:(NSString *)notification changeBlock:(FRPSliderCellChanged)block {
    return [[self alloc] cellWithTitle:title setting:setting min:min max:max postNotification:notification changeBlock:block];
}


- (instancetype)cellWithTitle:(NSString *)title setting:(FRPSettings *)setting min:(float)min max:(float)max postNotification:(NSString *)notification changeBlock:(FRPSliderCellChanged)block {
    FRPSliderCell *cell = [super initWithTitle:nil setting:setting];
    cell.postNotification = notification;
    cell.valueChanged = block;
    
    UISlider *sliderCell = [[UISlider alloc] initWithFrame:CGRectZero];
    sliderCell.minimumValue = min;
    sliderCell.maximumValue = max;
    sliderCell.value = [setting.value floatValue];
    [sliderCell addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];
    [cell.contentView addSubview:sliderCell];
    cell.sliderCell = sliderCell;
    
    UILabel *lLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    lLabel.text = [NSString stringWithFormat:@"%.2f",min];
    lLabel.numberOfLines = 1;
    lLabel.baselineAdjustment = UIBaselineAdjustmentAlignBaselines;
    lLabel.adjustsFontSizeToFitWidth = YES;
    lLabel.clipsToBounds = YES;
    lLabel.backgroundColor = [UIColor clearColor];
    lLabel.textColor = [UIColor blackColor];
    lLabel.textAlignment = NSTextAlignmentCenter;
    [cell.contentView addSubview:lLabel];
    cell.lLabel = lLabel;
    
    UILabel *rLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    rLabel.text = [NSString stringWithFormat:@"%.2f",max];
    rLabel.numberOfLines = 1;
    rLabel.baselineAdjustment = UIBaselineAdjustmentAlignBaselines;
    rLabel.adjustsFontSizeToFitWidth = YES;
    rLabel.clipsToBounds = YES;
    rLabel.backgroundColor = [UIColor clearColor];
    rLabel.textColor = [UIColor blackColor];
    rLabel.textAlignment = NSTextAlignmentCenter;
    [cell.contentView addSubview:rLabel];
    cell.rLabel = rLabel;
    
    UILabel *cLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    cLabel.text = title;
    cLabel.numberOfLines = 1;
    cLabel.baselineAdjustment = UIBaselineAdjustmentAlignBaselines;
    cLabel.adjustsFontSizeToFitWidth = YES;
    cLabel.clipsToBounds = YES;
    cLabel.backgroundColor = [UIColor clearColor];
    cLabel.textColor = [UIColor blackColor];
    cLabel.textAlignment = NSTextAlignmentLeft;
    [cell.contentView addSubview:cLabel];
    cell.cLabel = cLabel;
    
    UILabel *vLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    vLabel.text = [NSString stringWithFormat:@"%.2f",[setting.value floatValue]];
    vLabel.numberOfLines = 1;
    vLabel.baselineAdjustment = UIBaselineAdjustmentAlignBaselines;
    vLabel.adjustsFontSizeToFitWidth = YES;
    vLabel.clipsToBounds = YES;
    vLabel.backgroundColor = [UIColor clearColor];
    vLabel.textColor = [UIColor grayColor];
    vLabel.textAlignment = NSTextAlignmentRight;
    [cell.contentView addSubview:vLabel];
    cell.vLabel = vLabel;

    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.height = 75;
    return cell;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    float sliderW = self.contentView.frame.size.width/1.8;
    float sliderH = 25;
    float sliderX = self.contentView.frame.size.width/2-sliderW/2;
    float sliderY = self.contentView.frame.size.height-sliderH-10;
    self.sliderCell.frame = CGRectMake(sliderX, sliderY, sliderW, sliderH);

    float lLabelW = (self.contentView.frame.size.width-(self.contentView.frame.size.width/1.8))/2-10;
    float lLabelH = 25;
    float lLabelX = sliderX-lLabelW-5;
    float lLabelY = self.contentView.frame.size.height-lLabelH-10;
    self.lLabel.frame = CGRectMake(lLabelX, lLabelY, lLabelW, lLabelH);
    
    float rLabelW = (self.contentView.frame.size.width-(self.contentView.frame.size.width/1.8))/2-10;
    float rLabelH = 25;
    float rLabelX = sliderX+sliderW+5;
    float rLabelY = self.contentView.frame.size.height-rLabelH-10;
    self.rLabel.frame = CGRectMake(rLabelX, rLabelY, rLabelW, rLabelH);
    
    float cLabelW = self.contentView.frame.size.width/1.8;
    float cLabelH = 25;
    float cLabelX = 17;
    float cLabelY = 8;
    self.cLabel.frame = CGRectMake(cLabelX, cLabelY, cLabelW, cLabelH);
    
    float vLabelW = self.contentView.frame.size.width-(self.contentView.frame.size.width/1.8);
    float vLabelH = 25;
    float vLabelX = self.contentView.frame.size.width-vLabelW-25;
    float vLabelY = 8;
    self.vLabel.frame = CGRectMake(vLabelX, vLabelY, vLabelW, vLabelH);
}

- (void)sliderChanged:(UISlider *)slider {
    self.vLabel.text = [NSString stringWithFormat:@"%.2f",[slider value]];
    self.setting.value = [NSNumber numberWithFloat:[slider value]];
    if (self.valueChanged) {
        self.valueChanged(slider);
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:self.postNotification object:slider];
}

@end
