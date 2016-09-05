//
//  REDValidationComponent.h
//  REDFormValidation
//
//  Created by Sam Dye on 2016-03-04.
//  Copyright © 2016 Sam Dye. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "REDValidator.h"
#import "REDValidatableComponent.h"

@class REDValidationComponent;


/*!
 * @brief Delegate protocol for the @c REDValidationComponent @c that informs the delegate of validation events.
 */
@protocol REDValidationComponentDelegate <NSObject>

/*!
 * @brief Notifies the delegate when a UI component has received an input.
 * @param validationComponent The object handling validation.
 */
- (void)validationComponentReceivedInput:(REDValidationComponent *)validationComponent;

/*!
 * @brief Notifies the delegate when a UI component has resigned first responder status.
 * @param validationComponent The object handling validation.
 */
- (void)validationComponentEndedEditing:(REDValidationComponent *)validationComponent;

/*!
 * @brief Notifies the delegate when a UI component is about to be validated.
 * @param validationComponent The object handling validation.
 * @param uiComponent The UI component whose value is being validated.
 */
- (void)validationComponent:(REDValidationComponent *)validationComponent willValidateUIComponent:(NSObject<REDValidatableComponent> *)uiComponent;

/*!
 * @brief Notifies the delegate when a UI component has been validated
 * @param validationComponent The object handling validation.
 * @param uiComponent The UI component whose value is being validated.
 * @param error Error from network validation, if there is one.
 * @param result The result of the validation.
 */
- (void)validationComponent:(REDValidationComponent *)validationComponent didValidateUIComponent:(NSObject<REDValidatableComponent> *)uiComponent result:(REDValidationResult)result error:(NSError *)error;

@end


/*!
 * @brief Object that performs validation for and keeps track of validation state of individual UI components.
 */
@interface REDValidationComponent : NSObject

/*!
 * @brief The UI component being validated.
 */
@property (nonatomic, weak) NSObject<REDValidatableComponent> *uiComponent;

/*!
 * @brief Delegate that gets notified when the UI component is being validated.
 */
@property (nonatomic, weak) id<REDValidationComponentDelegate> delegate;

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
 * @discussion If false, the component's validation will be ANDed with the rest of the components that are false.
 * @see @c REDValidator.validationTree @c
 */
@property (nonatomic, assign) BOOL validatedInValidationTree;

/*!
 * @brief Whether the UI component should be validated. Allows temporary enabling and disabling the validation.
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
 * @brief Initializes and returns a new @c REDValidationComponent @c.
 * @param initialValue An initial value for the rule to validate.
 * @param event The event upon which the UI component will be validated.
 * @param rule The rule used to validate the UI component.
 * @return The initialized @c REDValidationComponent @c or nil if there was an error during initialization.
 */
- (instancetype)initWithInitialValue:(id)initialValue validationEvent:(REDValidationEvent)event rule:(id<REDValidationRuleType>)rule NS_DESIGNATED_INITIALIZER;

/*!
 * @brief Programmatically execute a validation.
 * @return The result of the validation.
 */
- (REDValidationResult)validate;

/*!
 * @brief Determines whether the component is valid upon creation.
 * @return Whether the component is unvalidated and has the default value of its class.
 */
- (REDValidationResult)evaluateDefaultValidity;

@end
