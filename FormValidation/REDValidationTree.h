//
//  REDValidationTree.h
//  REDFormValidation
//
//  Created by Sam Dye on 2016-08-22.
//  Copyright © 2016 Sam Dye. All rights reserved.
//

#import <Foundation/Foundation.h>

@class REDValidationComponent;


/*!
 * @brief Object that stores a representation of binary logic used to validate a group of REDValidationComponents.
 */
@interface REDValidationTree : NSObject

/*!
 * @brief Initializes and returns a validation tree that validates a single REDValidationComponent.
 */
+ (REDValidationTree *)single:(id)identifier;

/*!
 * @brief Initializes and returns a validation tree that ANDs an array of trees or identifiers.
 * @warning @c objects @c must be an array of REDValidationTrees or component identifiers.
 * @param objects An array of REDValidationTrees or component identifiers.
 * @return A new validation tree.
 */
+ (REDValidationTree *)and:(NSArray *)objects;

/*!
 * @brief Initializes and returns a validation tree that ORs an array of trees or identifiers.
 * @warning @c objects @c must be an array of REDValidationTrees or component identifiers.
 * @param objects An array of REDValidationTrees or component identifiers.
 * @return A new validation tree.
 */
+ (REDValidationTree *)or:(NSArray *)objects;

/*!
 * @brief Returns a validation tree that ANDs an array of trees or identifiers with the target tree.
 * @warning @c objects @c must be an array of REDValidationTrees or component identifiers.
 * @param objects An array of REDValidationTrees or component identifiers.
 * @return A modified validation tree.
 */
- (REDValidationTree *)and:(NSArray *)objects;

/*!
 * @brief Returns a validation tree that ORs an array of trees or identifiers with the target tree.
 * @warning @c objects @c must be an array of REDValidationTrees or component identifiers.
 * @param objects An array of REDValidationTrees or component identifiers.
 * @return A modified validation tree.
 */
- (REDValidationTree *)or:(NSArray *)objects;

/*!
 * @brief Validates a set of validation components.
 * @param components The validation components to be validated.
 * @param revalidate Whether the validation components should be revalidated or use their existing validation results.
 * @return The result of the validation.
 */
- (BOOL)validateComponents:(NSDictionary<id, REDValidationComponent *> *)components revalidate:(BOOL)revalidate;

@end
