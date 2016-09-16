//
//  REDValidation.h
//  REDFormValidation
//
//  Created by Sam Dye on 2016-03-04.
//  Copyright © 2016 Sam Dye. All rights reserved.
//

#import "REDValidator.h"
#import "REDValidatableComponent.h"


/*!
 * @brief Object that performs validation for and keeps track of validation state of individual UI components.
 */
@interface REDValidation : NSObject

/*!
 * @brief The UI component being validated.
 */
@property (nonatomic, weak) NSObject<REDValidatableComponent> *uiComponent;

/*!
 * @brief Whether the UI component should be validated. Allows temporarily enabling and disabling the validation. Default is YES.
 * @discussion If this validation has shouldValidate == YES, but the validator tracking this validation has shouldValidate == NO,
 * the validator's delegate methods will not be fired.
 */
@property (nonatomic, assign) BOOL shouldValidate;

/*!
 * @brief If enabled, the component value can be its default value and the component is considered valid. Default is NO for REDValidationRule and REDNetworkValidationRule.
 * @discussion This is used for fields that do not require a value. Generally  all of the fields of the form are not validated
 * at once, so this allows determining the validity of the form by evaluating fields without performing their validations.
 */
@property (nonatomic, assign) BOOL allowDefault;

/*!
 * @brief The current validity of the UI component based on the validation rule.
 */
@property (nonatomic, assign, readonly) REDValidationResult valid;

- (instancetype)init NS_UNAVAILABLE;

/*!
 * @brief Initializes and returns a new @c REDValidation @c.
 * @param identifier A unique value used to identify the validation.
 * @param rule The rule used to validate the UI component.
 * @return The initialized @c REDValidation @c or nil if there was an error during initialization.
 */
+ (instancetype)validationWithIdentifier:(id)identifier rule:(id<REDValidationRuleType>)rule;

/*!
 * @brief Initializes and returns a new @c REDValidation @c.
 * @param identifier A unique value used to identify the validation.
 * @param initialValue An initial value for the rule to validate.
 * @param event The event upon which the UI component will be validated.
 * @param rule The rule used to validate the UI component.
 * @return The initialized @c REDValidation @c or nil if there was an error during initialization.
 */
+ (instancetype)validationWithIdentifier:(id)identifier initialValue:(id)initialValue validationEvent:(REDValidationEvent)event rule:(id<REDValidationRuleType>)rule;

@end
