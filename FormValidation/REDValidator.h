//
//  REDValidator.h
//  REDFormValidation
//
//  Created by Sam Dye on 2016-03-04.
//  Copyright © 2016 Sam Dye. All rights reserved.
//

#import "REDValidationRuleType.h"

@class REDValidator, REDValidationTree, REDValidation;
@protocol REDValidatableComponent;

typedef NS_ENUM(NSInteger, REDValidationEvent) {
	REDValidationEventDefault, // validates on change and end editing
	REDValidationEventEndEditing // validates on end editing
};


/*!
 * @brief Delegate protocol for the @c REDValidator @c that informs the delegate of validation events.
 * @discussion If the delegate (generally a controller) handles the view/component changes when a validation occurs, the methods in this protocol should be implemented.
 */
@protocol REDValidatorDelegate <NSObject>
@optional

/*!
 * @brief Notifies the delegate when a UI component is about to be validated.
 * @param validator The validator object managing the form.
 * @param uiComponent The UI component whose value is being validated.
 */
- (void)validator:(REDValidator *)validator willValidateUIComponent:(NSObject<REDValidatableComponent> *)uiComponent;

/*!
 * @brief Notifies the delegate when a UI component has been validated.
 * @param validator The validator object managing the form.
 * @param uiComponent The UI component whose value is being validated.
 * @param error Error from network validation, if there is one.
 * @param result The result of the validation.
 */
- (void)validator:(REDValidator *)validator didValidateUIComponent:(NSObject<REDValidatableComponent> *)uiComponent result:(REDValidationResult)result error:(NSError *)error;

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
 *	If this is nil, all of the validations are ANDed.
 *	If this is not nil but doesn't include all of the validations, the remaining ones are ANDed.
 */
@property (nonatomic, strong) REDValidationTree *validationTree;

/*!
 * @brief A dictionary containing the identifier-to-validation relationships that are currently being tracked.
 */
@property (nonatomic, readonly) NSDictionary<id, REDValidation *> *validations;

/*!
 * @brief The current validity of the form.
 */
@property (nonatomic, assign, readonly) REDValidationResult valid;

/*!
 * @brief Whether the form should be validated. Default is YES.
 * @discussion When false, no further form validations will occur (the individual components will still be validated).
 */
@property (nonatomic, assign) BOOL shouldValidate;

/*!
 * @brief A time to delay prior to performing validation of a component when it is changed. This only applies to non-network validations. Default is 0.0.
 */
@property (nonatomic, assign) NSTimeInterval inputDelay;

/*!
 * @brief A time to delay prior to performing network validation of a component when it is changed. This only applies to network validations. Default is 0.0.
 */
@property (nonatomic, assign) NSTimeInterval networkInputDelay;

/*!
 * @brief Programmatically execute a validation. Generally not necessary.
 * @return Result of validation.
 */
- (REDValidationResult)validate;

/*!
 * @brief Starts tracking the given validation.
 * @param validation The validation that will be tracked and evaluated.
 */
- (void)addValidation:(REDValidation *)validation;

/*!
 * @brief Stops tracking the validation with the given identifier.
 * @discussion The validation will not be removed if it is still being used in the @c validationTree @c.
 * @param identifier The identifier for the validation that will be removed.
 * @return Returns whether the validation was removed successfully.
 */
- (BOOL)removeValidationWithIdentifier:(id)identifier;

@end
