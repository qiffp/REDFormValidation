//
//  REDValidationTree.h
//  REDFormValidation
//
//  Created by Sam Dye on 2016-08-22.
//  Copyright © 2016 Sam Dye. All rights reserved.
//

#import "REDValidationRuleType.h"

@class REDValidation;


/*!
 * @brief Object that stores a representation of binary logic used to validate a group of REDValidations.
 */
@interface REDValidationTree : NSObject

/*!
 * @brief Initializes and returns a validation tree that validates a single REDValidation.
 */
+ (REDValidationTree *)single:(id)identifier;

/*!
 * @brief Initializes and returns a validation tree that ANDs an array of trees or identifiers.
 * @discussion NOTE: The intent of AND is to require multiple form fields so that `Valid` AND `Unvalidated` == `Invalid`
 * @warning @c objects @c must be an array of REDValidationTrees or validation identifiers.
 * @param objects An array of REDValidationTrees or validation identifiers.
 * @return A new validation tree.
 */
+ (REDValidationTree *)and:(NSArray *)objects;

/*!
 * @brief Initializes and returns a validation tree that ORs an array of trees or identifiers.
 * @discussion NOTE: The intent of OR is that `Valid` OR `Unvalidated` == `Valid` so that your form can require either one field or another.
 * The intent is NOT that `Valid` OR `Invalid` == `Valid`. The result of this operation will be `Invalid` for both AND and OR.
 * @warning @c objects @c must be an array of REDValidationTrees or validation identifiers.
 * @param objects An array of REDValidationTrees or validation identifiers.
 * @return A new validation tree.
 */
+ (REDValidationTree *)or:(NSArray *)objects;

/*!
 * @brief Validates a set of validations.
 * @param validations The validations to be validated.
 * @param revalidate Whether the validations should be revalidated or use their existing results.
 * @return The result of the validation.
 */
- (REDValidationResult)validateValidations:(NSDictionary<id, REDValidation *> *)validations revalidate:(BOOL)revalidate;

@end
