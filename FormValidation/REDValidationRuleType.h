//
//  REDValidationRuleType.h
//  REDFormValidation
//
//  Created by Sam Dye on 2016-03-04.
//  Copyright © 2016 Sam Dye. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol REDValidatableComponent;

typedef BOOL (^REDValidationRuleBlock)(id value);

typedef void (^REDNetworkValidationRuleResultBlock)(BOOL result, NSError *error);
typedef NSURLSessionTask * (^REDNetworkValidationRuleBlock)(id value, REDNetworkValidationRuleResultBlock completion);

typedef NS_ENUM(NSInteger, REDValidationResult) {
	REDValidationResultUnvalidated,
	REDValidationResultInvalid,
	REDValidationResultValid,
	REDValidationResultDefaultValid,
	REDValidationResultPending
};


/*!
 * @brief Protocol describing behaviour of validation rules.
 */
@protocol REDValidationRuleType <NSObject>

/*!
 * @brief Validates the specified component using the validation rule.
 * @param component The component that is being validated.
 * @return The result of the validation.
 */
- (REDValidationResult)validate:(NSObject<REDValidatableComponent> *)component;

/*!
 * @brief Validates the specified value using the validation rule.
 * @param value The value that is being validated.
 * @return The result of the validation.
 */
- (REDValidationResult)validateValue:(id)value;

/*!
 * @brief Cancel the validation that is currently in progress. Intended for network validations.
 */
- (void)cancel;

/*!
 * @brief If enabled, the component value can be its default value and the component is considered valid.
 * @discussion This is used for fields that do not require a value. Generally  all of the fields of the form are not validated
 * at once, so this allows determining the validity of the form by evaluating fields without performing their validations.
 */
@property (nonatomic, assign) BOOL allowDefault;

@end


/*!
 * @brief Delegate protocol for the @c REDNetworkValidationRule @c that informs the delegate of validation events.
 */
@protocol REDNetworkValidationRuleDelegate <NSObject>

/*!
 * @brief Notifies the delegate when a network validation has completed.
 * @param rule The validation rule that is being used.
 * @param component The component that has been validated.
 * @param result The result of the validation.
 * @param error An error that has occurred during the validation process.
 */
- (void)validationRule:(id<REDValidationRuleType>)rule completedNetworkValidationOfComponent:(NSObject<REDValidatableComponent> *)component withResult:(REDValidationResult)result error:(NSError *)error;

@end


/*!
 * @brief Object that validates components based on a specified rule.
 */
@interface REDValidationRule : NSObject <REDValidationRuleType>

/*!
 * @brief Initializes and returns a @c REDValidationRule @c using the specified rule.
 * @param block The validation rule to be used.
 */
+ (instancetype)ruleWithBlock:(REDValidationRuleBlock)block;

@end


/*!
 * @brief Object that validates components based on a specified rule that requires network calls.
 */
@interface REDNetworkValidationRule : NSObject <REDValidationRuleType>

/*!
 * @brief Delegate that gets notified of network validation events.
 */
@property (nonatomic, weak) id<REDNetworkValidationRuleDelegate> delegate;

/*!
 * @brief Initializes and returns a @c REDNetworkValidationRule @c using the specified rule.
 * @param block The validation rule to be used.
 */
+ (instancetype)ruleWithBlock:(REDNetworkValidationRuleBlock)block;

@end
