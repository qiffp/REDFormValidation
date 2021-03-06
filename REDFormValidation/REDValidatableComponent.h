//
//  REDValidatableComponent.h
//  REDFormValidation
//
//  Created by Sam Dye on 2016-06-10.
//  Copyright © 2016 Sam Dye. All rights reserved.
//

#import "REDValidationRuleType.h"

OBJC_EXTERN float const kUISliderDefaultValue;
OBJC_EXTERN double const kUIStepperDefaultValue;
OBJC_EXTERN NSString *const kUITextFieldDefaultValue;
OBJC_EXTERN NSString *const kUITextViewDefaultValue;

@class REDValidator;

/*!
 * @brief Protocol that provides the validation interface for a component.
 * @discussion If the view/component handles its own changes when a validation occurs, the methods in this protocol should be implemented by the component.
 */
@protocol REDValidatableComponent <NSObject>

/*!
 * @brief Provides access to the validated property of the component.
 * @return The value of the validated property of the component.
 */
@property (nonatomic, strong, readonly) id validatedValue;

/*!
 * @brief Provides access to the default value of the validated property of the component.
 * @return The default value of the validated property of the component.
 */
@property (nonatomic, strong, readonly) id defaultValue;

@optional

/*!
 * @brief Notifies the component when it is about to be validated.
 * @param validator The validator object managing the form.
 */
- (void)validatorWillValidateUIComponent:(REDValidator *)validator;

/*!
 * @brief Notifies the component when it has been validated.
 * @param validator The validator object managing the form.
 * @param error Error from network validation, if there is one.
 * @param result The result of the validation.
 */
- (void)validator:(REDValidator *)validator didValidateUIComponentWithResult:(REDValidationResult)result error:(NSError *)error;

@end


@interface UISlider (REDValidatableComponent) <REDValidatableComponent>
@end

@interface UIStepper (REDValidatableComponent) <REDValidatableComponent>
@end

@interface UITextField (REDValidatableComponent) <REDValidatableComponent>
@end

@interface UITextView (REDValidatableComponent) <REDValidatableComponent>
@end
