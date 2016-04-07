//
//  REDValidator.h
//  REDFormValidation
//
//  Created by Sam Dye on 2016-03-04.
//  Copyright © 2016 Sam Dye. All rights reserved.
//

#import <UIKit/UIKit.h>

@class REDValidator;
@protocol REDValidationRuleProtocol;

typedef BOOL (^REDTableViewValidationBlock)(REDValidator *validator);

typedef NS_ENUM(NSInteger, REDValidationEvent) {
	REDValidationEventChange = (1 << 0),
	REDValidationEventBeginEditing = (1 << 1),
	REDValidationEventEndEditing = (1 << 2),
	REDValidationEventAll = (1 << 3)
};

/*!
 * @brief Delegate protocol for the REDValidator, which handles validation for all registered form UI components.
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
 * @brief Object that performs validation for and keeps track of validation state of a form.
 */
@interface REDValidator : NSObject

/*!
 * @brief Delegate that gets notified when the form and its components are validated.
 */
@property (nonatomic, weak) id<REDValidatorDelegate> delegate;

/*!
 * @brief Block that contains logic that determines whether the form is valid. Not required.
 * @discussion
 *	If this is nil, all of the component validations are ANDed.
 *	If this is not nil but doesn't include all of the component validations, the remaining ones are ANDed.
 *
 *	The block should only use the `validationIsValid:` method.
 * @code
 * validator.validationBlock = ^BOOL(REDValidator *v) {
 *	return [v validationIsValid:kREDValidationEmail] || [v validationIsValid:kREDValidationName];
 * }
 * @endcode
 * @see validationIsValid:
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
 * @brief Creates a new validation.
 * @param tag The tag that will be assigned to the validation.
 * @param event The event upon which the UI component will be validated.
 * @param rule The rule used to validate the UI component.
 */
- (void)addValidationWithTag:(NSInteger)tag validateOn:(REDValidationEvent)event rule:(id<REDValidationRuleProtocol>)rule;

/*!
 * @brief Sets the UI component that should be validated with the given validation.
 * @param component The UI component that should be validated.
 * @param tag The tag of the desired validation.
 */
- (void)setComponent:(UIView *)component forValidation:(NSInteger)tag;

/*!
 * @brief Returns the `valid` state of a certain validation tag.
 * @discussion This is only intended for use in the `validationBlock`.
 * @param tag The tag of the desired validation.
 * @return The `valid` state of the given validation tag.
 * @see validationBlock
 */
- (BOOL)validationIsValid:(NSInteger)tag;

@end
