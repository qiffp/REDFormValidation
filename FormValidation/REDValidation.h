//
//  REDValidation.h
//  REDFormValidation
//
//  Created by Sam Dye on 2016-03-04.
//  Copyright © 2016 Sam Dye. All rights reserved.
//

#import "REDValidator.h"
#import "REDValidatableComponent.h"

@class REDValidation;


/*!
 * @brief Delegate protocol for the @c REDValidation @c that informs the delegate of validation events.
 */
@protocol REDValidationDelegate <NSObject>

/*!
 * @brief Notifies the delegate when the UI component has been changed.
 * @param validatin The object handling validation.
 */
- (void)validationDidUpdateUIComponent:(REDValidation *)validation;

/*!
 * @brief Notifies the delegate when a UI component has received an input.
 * @param validation The object handling validation.
 */
- (void)validationUIComponentDidReceiveInput:(REDValidation *)validation;

/*!
 * @brief Notifies the delegate when a UI component has resigned first responder status.
 * @param validation The object handling validation.
 */
- (void)validationUIComponentDidEndEditing:(REDValidation *)validation;

/*!
 * @brief Notifies the delegate when a UI component is about to be validated.
 * @param validation The object handling validation.
 * @param uiComponent The UI component whose value is being validated.
 */
- (void)validation:(REDValidation *)validation willValidateUIComponent:(NSObject<REDValidatableComponent> *)uiComponent;

/*!
 * @brief Notifies the delegate when a UI component has been validated
 * @param validation The object handling validation.
 * @param uiComponent The UI component whose value is being validated.
 * @param error Error from network validation, if there is one.
 * @param result The result of the validation.
 */
- (void)validation:(REDValidation *)validation didValidateUIComponent:(NSObject<REDValidatableComponent> *)uiComponent result:(REDValidationResult)result error:(NSError *)error;

@end


/*!
 * @brief Object that performs validation for and keeps track of validation state of individual UI components.
 */
@interface REDValidation : NSObject

/*!
 * @brief The UI component being validated.
 */
@property (nonatomic, weak) NSObject<REDValidatableComponent> *uiComponent;

/*!
 * @brief Delegate that gets notified when the UI component is being validated.
 */
@property (nonatomic, weak) id<REDValidationDelegate> delegate;

/*!
 * @brief The current validity of the UI component based on the validation rule.
 */
@property (nonatomic, assign, readonly) REDValidationResult valid;

/*!
 * @brief A rule describing the validation of the UI component.
 */
@property (nonatomic, strong, readonly) id<REDValidationRuleType> rule;

/*!
 * @brief Describes whether the UI component is being used in the validation tree of the @c REDValidator @c.
 * @discussion If false, the validation result will be ANDed with the rest of the validations are not validated in the validation tree.
 */
@property (nonatomic, assign) BOOL validatedInValidationTree;

/*!
 * @brief Whether the UI component should be validated. Allows temporary enabling and disabling the validation. Default is YES.
 */
@property (nonatomic, assign) BOOL shouldValidate;

/*!
 * @brief An initial value to be validated.
 * @discussion This is used with UITableView forms. If a cell contains a form element but is offscreen and
 * hasn't been loaded, its value can't be validated. If the cell is being pre-filled with a value that may be
 * invalid, this property allows it to be valided upon form instantiation.
 */
@property (nonatomic, readonly) id initialValue;

/*!
 * @brief A unique value used to identify the validation.
 */
@property (nonatomic, readonly) id identifier;

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

/*!
 * @brief Programmatically execute a validation.
 * @return The result of the validation.
 */
- (REDValidationResult)validate;

/*!
 * @brief Determines whether the validation is valid upon creation.
 * @return Whether the validation is unvalidated and has the default value of its class.
 */
- (REDValidationResult)evaluateDefaultValidity;

@end
