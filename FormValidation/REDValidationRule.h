//
//  REDValidationRule.h
//  REDFormValidation
//
//  Created by Sam Dye on 2016-03-04.
//  Copyright © 2016 Sam Dye. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef BOOL (^REDValidationBlock)(UIView *component);

typedef void (^REDNetworkValidationResultBlock)(BOOL success, NSError *error);
typedef NSURLSessionTask * (^REDNetworkValidationBlock)(UIView *component, REDNetworkValidationResultBlock completion);

typedef NS_ENUM(NSInteger, REDValidationResult) {
	REDValidationResultUnknown = (1 << 0),
	REDValidationResultFailure = (1 << 1),
	REDValidationResultSuccess = (1 << 2),
	REDValidationResultPending = (1 << 3)
};

/*!
 * @brief Protocol describing behaviour of validation rules
 */
@protocol REDValidationRule <NSObject>

/*!
 * @brief Validate the specified component using the validation rule
 * @param component The component that is being evaluated.
 * @return The result of the validation.
 */
- (REDValidationResult)validate:(UIView *)component;

/*!
 * @brief Cancel the validation that is currently in progress. Intended for network validations.
 */
- (void)cancel;

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
- (void)validationRule:(id<REDValidationRule>)rule completedNetworkValidationOfComponent:(UIView *)component withResult:(REDValidationResult)result error:(NSError *)error;

@end


/*!
 * @brief Object that validates components based on a specified rule.
 */
@interface REDValidationRule : NSObject <REDValidationRule>

/*!
 * @brief Initializes and returns a @c REDValidationRule @c using the specified rule.
 * @param block The validation rule to be used.
 */
+ (instancetype)ruleWithBlock:(REDValidationBlock)block;

@end


/*!
 * @brief Object that validates components based on a specified rule that requires network calls.
 */
@interface REDNetworkValidationRule : NSObject <REDValidationRule>

/*!
 * @brief Delegate that gets notified of network validation events.
 */
@property (nonatomic, weak) id<REDNetworkValidationRuleDelegate> delegate;

/*!
 * @brief Initializes and returns a @c REDNetworkValidationRule @c using the specified rule.
 * @param block The validation rule to be used.
 */
+ (instancetype)ruleWithBlock:(REDNetworkValidationBlock)block;

@end
