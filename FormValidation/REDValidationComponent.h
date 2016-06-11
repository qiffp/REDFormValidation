//
//  REDValidationComponent.h
//  REDFormValidation
//
//  Created by Sam Dye on 2016-03-04.
//  Copyright © 2016 Sam Dye. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "REDValidator.h"

@class REDValidationComponent;
@protocol REDValidationRule;


/*!
 * @brief Delegate protocol for the @c REDValidationComponent @c that informs the delegate of validation events.
 */
@protocol REDValidationComponentDelegate <NSObject>

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
 * @param result The result of the validation.
 */
- (void)validationComponent:(REDValidationComponent *)validationComponent didValidateUIComponent:(NSObject<REDValidatableComponent> *)uiComponent result:(BOOL)result;

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
@property (nonatomic, assign, readonly) BOOL valid;

/*!
 * @brief Describes whether the UI component has yet been validated or has been modified such that it requires revalidation.
 * @see @c valid @c
 */
@property (nonatomic, assign, readonly) BOOL validated;

/*!
 * @brief Describes whether the UI component is being used in the validation block of the @c REDValidator @c.
 * @discussion If false, the component's validation is ANDed with the rest of the components that are false.
 * @see @c REDValidator.validationBlock @c
 */
@property (nonatomic, assign) BOOL validatedInValidatorBlock;

/*!
 * @brief Whether the UI component should be validated. Allows temporary enabling and disabling the validation.
 */
@property (nonatomic, assign) BOOL shouldValidate;

/*!
 * @brief Initializes and returns a new @c REDValidationComponent @c.
 * @param event The event upon which the UI component will be validated.
 * @param rule The rule used to validate the UI component.
 * @return The initialized @c REDValidationComponent @c or nil if there was an error during initialization.
 */
- (instancetype)initWithValidationEvent:(REDValidationEvent)event rule:(id<REDValidationRule>)rule NS_DESIGNATED_INITIALIZER;

/*!
 * @brief Programmatically execute a validation.
 * @return The result of the validation.
 */
- (BOOL)validate;

/*!
 * @brief Resets the valid and validated state of the validation object.
 * @see @c valid @c, @c validated @c
 */
- (void)reset;

@end
