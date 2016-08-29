//
//  REDValidator.h
//  REDFormValidation
//
//  Created by Sam Dye on 2016-03-04.
//  Copyright © 2016 Sam Dye. All rights reserved.
//

#import "REDValidationRule.h"

@class REDValidator, REDValidationList;
@protocol REDValidatableComponent;

typedef NS_ENUM(NSInteger, REDValidationEvent) {
	REDValidationEventChange = (1 << 0),
	REDValidationEventBeginEditing = (1 << 1),
	REDValidationEventEndEditing = (1 << 2),
	REDValidationEventAll = (1 << 3)
};


/*!
 * @brief Delegate protocol for the @c REDValidator @c that informs the delegate of validation events.
 * @discussion If the delegate (generally a controller) handles the view/component changes when a validation occurs, the methods in this protocol should be implemented.
 * @see @c REDValidatorComponent @c
 */
@protocol REDValidatorDelegate <NSObject>
@optional

/*!
 * @brief Notifies the delegate when a UI component is about to be validated.
 * @param validator The validator object managing the form.
 * @param uiComponent The UI component whose value is being validated.
 */
- (void)validator:(REDValidator *)validator willValidateComponent:(NSObject<REDValidatableComponent> *)component;

/*!
 * @brief Notifies the delegate when a UI component has been validated.
 * @param validator The validator object managing the form.
 * @param uiComponent The UI component whose value is being validated.
 * @param result The result of the validation.
 */
- (void)validator:(REDValidator *)validator didValidateComponent:(NSObject<REDValidatableComponent> *)component result:(REDValidationResult)result;

/*!
 * @brief Notifies the delegate when the entire form has been validated.
 * @discussion This fires each time `validate` is called on the validator and each time a component is validated.
 * @param validator The validator object managing the form.
 * @param result The result of the validation.
 */
- (void)validator:(REDValidator *)validator didValidateFormWithResult:(REDValidationResult)result;

@end


/*!
 * @brief Object that performs validation for and keeps track of validation state of a form.
 */
@interface REDValidator : NSObject

/*!
 * @brief Delegate that gets notified when the form and its components are validated.
 */
@property (nonatomic, weak) id<REDValidatorDelegate> delegate;

/*!
 * @brief Object that contains logic that determines whether the form is valid. Not required.
 * @discussion
 *	If this is nil, all of the component validations are ANDed.
 *	If this is not nil but doesn't include all of the component validations, the remaining ones are ANDed.
 */
@property (nonatomic, strong) REDValidationList *validationList;

/*!
 * @brief The current validity of the form.
 */
@property (nonatomic, assign, readonly) REDValidationResult valid;

/*!
 * @brief Whether the form should be validated.
 * @discussion When false, no further form validations will occur (the individual components will still be validated).
 */
@property (nonatomic, assign) BOOL shouldValidate;

/*!
 * @brief Programmatically execute a validation. Generally not necessary.
 * @return Result of validation.
 */
- (REDValidationResult)validate;

/*!
 * @brief Creates a new validation.
 * @param identifier The identifier that will be assigned to the validation.
 * @param event The event upon which the UI component will be validated.
 * @param rule The rule used to validate the UI component.
 */
- (void)addValidation:(id)identifier validateOn:(REDValidationEvent)event rule:(id<REDValidationRule>)rule;

/*!
 * @brief Removes the validation with the given identifier.
 * @discussion The validation will not be removed if it is still being used in the @c validatorBlock @c.
 * @param identifier The identifier for the validation that will be removed.
 * @return Returns whether the validation was removed successfully.
 * @see @c validatorBlock @c
 */
- (BOOL)removeValidation:(id)identifier;

/*!
 * @brief Allows temporarily enabing and disabling the given validation.
 * @param shouldValidate Whether the validation with the given identifier should be validated.
 * @param identifier The identifier for the validation that will be removed.
 */
- (void)setShouldValidate:(BOOL)shouldValidate forValidation:(id)identifier;

/*!
 * @brief Sets the UI component that should be validated with the given validation.
 * @note All @c UIView @c objects conform to @c REDValidatorComponent @c.
 * @param component The UI component that should be validated.
 * @param identifier The identifier of the desired validation.
 */
- (void)setComponent:(NSObject<REDValidatableComponent> *)component forValidation:(id)identifier;

@end
