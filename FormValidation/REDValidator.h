//
//  REDValidator.h
//  REDFormValidation
//
//  Created by Sam Dye on 2016-03-04.
//  Copyright © 2016 Sam Dye. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "REDValidationComponent.h"

@class REDValidator;

typedef BOOL (^REDTableViewValidationBlock)(REDValidator *validator);

@protocol REDValidatorDelegate <NSObject>
@optional
- (void)validator:(REDValidator *)validator willValidateComponent:(UIView *)component;
- (void)validator:(REDValidator *)validator didValidateComponent:(UIView *)component result:(BOOL)result;
- (void)validator:(REDValidator *)validator didValidateFormWithResult:(BOOL)result;
@end

@interface REDValidator : NSObject

@property (nonatomic, assign) BOOL shouldValidate;
@property (nonatomic, weak) id<REDValidatorDelegate> delegate;
@property (nonatomic, copy) REDTableViewValidationBlock validationBlock;

- (instancetype)initWithView:(UIView *)view;

- (void)setRule:(id<REDValidationRuleProtocol>)rule forComponentWithTag:(NSInteger)tag validateOn:(REDValidationEvent)event;

- (REDValidationComponent *)validationComponentWithTag:(NSInteger)tag;

- (BOOL)validate;

@end
