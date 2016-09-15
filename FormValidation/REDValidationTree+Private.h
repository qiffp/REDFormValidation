//
//  REDValidationTree+Private.h
//  REDFormValidation
//
//  Created by Sam Dye on 2016-08-29.
//  Copyright © 2016 Sam Dye. All rights reserved.
//

typedef NS_ENUM(NSUInteger, REDValidationOperation) {
	REDValidationOperationNone = 1,
	REDValidationOperationAND,
	REDValidationOperationOR,
};


@interface REDValidationTree (Private)

/*!
 * @brief Evaluates whether the tree uses the given validations.
 * @param validations The validations to be evaluated.
 */
- (void)evaluateValidations:(NSDictionary<id, REDValidation *> *)validations;

/*!
 * @brief Determines a single REDValidationResult based on a REDValidationResult mask's value.
 * @param mask A REDValidationResult mask (ORed results).
 * @param operation The operation that the tree is performing.
 * @result A single REDValidationResult.
 */
+ (REDValidationResult)resultForMask:(REDValidationResult)mask operation:(REDValidationOperation)operation;

@end
