//
//  REDValidation+Private.h
//  REDFormValidation
//
//  Created by Sam Dye on 2016-09-15.
//  Copyright © 2016 Sam Dye. All rights reserved.
//

#import "REDValidation.h"

/*!
 * @brief Delegate protocol for the @c REDValidation @c that informs the delegate of validation events.
 */
@protocol REDValidationDelegate <NSObject>

/*!
 * @brief Notifies the delegate when the UI component has been changed.
 * @param validation The object handling validation.
 * @param uiComponent The validation's new uiComponent object.
 */
- (void)validation:(REDValidation *)validation didUpdateWithUIComponent:(NSObject<REDValidatableComponent> *)uiComponent;

/*!
 * @brief Requests the amount of time to delay a validation.
 * @param validation The object handling validation.
 */
- (NSTimeInterval)delayForValidation:(REDValidation *)validation;

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


@interface REDValidation ()

/*!
 * @brief Delegate that gets notified when the UI component is being validated.
 */
@property (nonatomic, weak) id<REDValidationDelegate> delegate;

/*!
 * @brief Describes whether the UI component is being used in the validation tree of the @c REDValidator @c.
 * @discussion If false, the validation result will be ANDed with the rest of the validations are not validated in the validation tree.
 */
@property (nonatomic, assign) BOOL validatedInValidationTree;

/*!
 * @brief A rule describing the validation of the UI component.
 */
@property (nonatomic, strong, readonly) id<REDValidationRuleType> rule;

/*!
 * @brief An initial value to be validated.
 * @discussion This is used with UITableView forms. If a cell contains a form element but is offscreen and
 * hasn't been loaded, its value can't be validated. If the cell is being pre-filled with a value that may be
 * invalid, this property allows it to be valided upon form instantiation.
 */
@property (nonatomic, strong, readonly) id initialValue;

/*!
 * @brief If enabled, the component value can be its default value and the component is considered valid.
 * @discussion This is used for fields that do not require a value. Generally  all of the fields of the form are not validated
 * at once, so this allows determining the validity of the form by evaluating fields without performing their validations.
 */
@property (nonatomic, assign, readonly) BOOL allowDefault;

/*!
 * @brief A unique value used to identify the validation.
 */
@property (nonatomic, strong, readonly) id identifier;

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
