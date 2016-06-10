//
//  REDValidator.h
//  REDFormValidation
//
//  Created by Sam Dye on 2016-03-04.
//  Copyright © 2016 Sam Dye. All rights reserved.
//

#import <UIKit/UIKit.h>

@class REDValidator;
@protocol REDValidationRule;

typedef BOOL (^REDTableViewValidationBlock)(REDValidator *validator);

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
- (void)validator:(REDValidator *)validator willValidateComponent:(UIView *)component;

/*!
 * @brief Notifies the delegate when a UI component has been validated.
 * @param validator The validator object managing the form.
 * @param uiComponent The UI component whose value is being validated.
 * @param result The result of the validation.
 */
- (void)validator:(REDValidator *)validator didValidateComponent:(UIView *)component result:(BOOL)result;

/*!
 * @brief Notifies the delegate when the entire form has been validated.
 * @discussion This fires each time `validate` is called on the validator and each time a component is validated.
 * @param validator The validator object managing the form.
 * @param result The result of the validation.
 */
- (void)validator:(REDValidator *)validator didValidateFormWithResult:(BOOL)result;

@end


/*!
 * @brief Protocol to notify components of their validation events.
 * @discussion If the view/component handles its own changes when a validation occurs, the methods in this protocol should be implemented by the component.
 * @see @c REDValidatorDelegate @c
 */
@protocol REDValidatorComponent <NSObject>
@optional

/*!
 * @brief Notifies the component when it is about to be validated.
 * @param validator The validator object managing the form.
 */
- (void)validatorWillValidateComponent:(REDValidator *)validator;

/*!
 * @brief Notifies the component when it has been validated.
 * @param validator The validator object managing the form.
 * @param result The result of the validation.
 */
- (void)validator:(REDValidator *)validator didValidateComponentWithResult:(BOOL)result;

@end

/*!
 * @brief All @c UIView @c objects conform to @c REDValidatorComponent @c.
 * @discussion This makes it so that the protocol can be made obvious when using @c setComponent:forValidation: @c. Since all of the protocol methods are optional, there are no restrictions on which @c UIView @c objects can be used as the the component.
 * @see @c setComponent:forValidation: @c
 */
@interface UIView (REDValidator) <REDValidatorComponent>
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
 * @brief Block that contains logic that determines whether the form is valid. Not required.
 * @warning Logical operators used in this block MUST be bitwise operators so that they don't get short-circuited.
 * @discussion
 *	If this is nil, all of the component validations are ANDed.
 *	If this is not nil but doesn't include all of the component validations, the remaining ones are ANDed.
 *
 *	The block should only use the @c validationIsValid: @c method.
 * @code
 * validator.validationBlock = ^BOOL(REDValidator *v) {
 *	return [v validationIsValid:kREDValidationEmail] | [v validationIsValid:kREDValidationName];
 * }
 * @endcode
 * @see @c validationIsValid: @c
 */
@property (nonatomic, copy) REDTableViewValidationBlock validationBlock;

/*!
 * @brief The current validity of the form.
 */
@property (nonatomic, assign, readonly) BOOL valid;

/*!
 * @brief Whether the form should be validated.
 * @discussion When false, no further form validations will occur (the individual components will still be validated).
 */
@property (nonatomic, assign) BOOL shouldValidate;

/*!
 * @brief Programmatically execute a validation. Generally not necessary.
 * @return Result of validation.
 */
- (BOOL)validate;

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
- (void)setComponent:(UIView<REDValidatorComponent> *)component forValidation:(id)identifier;

/*!
 * @brief Returns the @c valid @c state of a certain validation identifier.
 * @discussion This is only intended for use in the @c validationBlock @c.
 * @param identifier The identifier of the desired validation.
 * @return The @c valid @c state of the given validation identifier.
 * @see @c validationBlock @c
 */
- (BOOL)validationIsValid:(id)identifier;

@end
