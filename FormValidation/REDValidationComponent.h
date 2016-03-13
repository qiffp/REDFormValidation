//
//  REDValidationComponent.h
//  REDFormValidation
//
//  Created by Sam Dye on 2016-03-04.
//  Copyright © 2016 Sam Dye. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "REDValidator.h"
#import "REDValidationRule.h"

@class REDValidationComponent;

@protocol REDValidationComponentDelegate <NSObject>
@optional
- (void)validationComponent:(REDValidationComponent *)validationComponent willValidateUIComponent:(UIView *)uiComponent;
- (void)validationComponent:(REDValidationComponent *)validationComponent didValidateUIComponent:(UIView *)uiComponent result:(BOOL)result;
@end

@interface REDValidationComponent : NSObject

@property (nonatomic, strong) id<REDValidationRuleProtocol> rule;
@property (nonatomic, weak) UIView *uiComponent;
@property (nonatomic, weak) id<REDValidationComponentDelegate> delegate;
@property (nonatomic, assign) NSInteger tag;
@property (nonatomic, readonly, assign) BOOL valid;
@property (nonatomic, assign) BOOL validatedInValidatorBlock;

- (instancetype)initWithUIComponent:(UIView *)uiComponent validateOn:(REDValidationEvent)event;

- (BOOL)validateUIComponent:(UIView *)uiComponent withCallbacks:(BOOL)callback;

@end
