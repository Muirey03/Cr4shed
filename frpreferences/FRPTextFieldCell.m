//
//  FRPSwitchCell.m
//  FRPreferences
//
//  Created by Fouad Raheb on 7/2/15.
//  Copyright (c) 2015 F0u4d. All rights reserved.
//

#import "FRPTextFieldCell.h"

@interface FRPTextFieldCell ()

@property (nonatomic, strong) UITextField *textField;

@end

@implementation FRPTextFieldCell

+ (instancetype)cellWithTitle:(NSString *)title setting:(FRPSettings *)setting placeholder:(NSString *)placeholder postNotification:(NSString *)notification changeBlock:(FRPTextFieldCellChanged)block {
    return [[self alloc] cellWithTitle:title setting:setting placeholder:placeholder postNotification:notification changeBlock:block];
}

- (instancetype)cellWithTitle:(NSString *)title setting:(FRPSettings *)setting placeholder:(NSString *)placeholder postNotification:(NSString *)notification changeBlock:(FRPTextFieldCellChanged)block {
    FRPTextFieldCell *cell = [super initWithTitle:title setting:setting];
    cell.setting = setting;
    cell.postNotification = notification;
    cell.valueChanged = block;
    self.textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 190, 30)];
    [self.textField setDelegate:self];
    [self.textField setTextAlignment:NSTextAlignmentRight];
    [self.textField setClearButtonMode:UITextFieldViewModeWhileEditing];
    [self.textField setText:setting.value];
    [self.textField setPlaceholder:placeholder];
    [self.textField addTarget:self action:@selector(textFieldChanged:) forControlEvents:UIControlEventEditingChanged];
    self.textField.returnKeyType = UIReturnKeyDone;
    cell.accessoryView = self.textField;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    return cell;
}

- (void)textFieldChanged:(UITextField *)textField {
    self.setting.value = [textField text];
    if (self.valueChanged) {
        self.valueChanged(textField);
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:self.postNotification object:textField];
}

- (BOOL)textFieldShouldReturn:(id)textField {
    [textField resignFirstResponder];
    return NO;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.textField.tintColor = self.tintUIColor;
}

@end
