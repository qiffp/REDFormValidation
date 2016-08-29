//
//  REDValidationList.h
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
@interface REDValidationList : NSObject

/*!
 * @brief Initializes and returns a validation list that validates a single REDValidationComponent.
 */
+ (REDValidationList *)single:(id)identifier;

/*!
 * @brief Initializes and returns a validation list that ANDs an array of lists or identifiers.
 * @warning @c objects @c must be an array of REDValidationLists or component identifiers.
 * @param objects An array of REDValidationLists or component identifiers.
 * @return A new validation list.
 */
+ (REDValidationList *)and:(NSArray *)objects;

/*!
 * @brief Initializes and returns a validation list that ORs an array of lists or identifiers.
 * @warning @c objects @c must be an array of REDValidationLists or component identifiers.
 * @param objects An array of REDValidationLists or component identifiers.
 * @return A new validation list.
 */
+ (REDValidationList *)or:(NSArray *)objects;

/*!
 * @brief Returns a validation list that ANDs an array of lists or identifiers with the target list.
 * @warning @c objects @c must be an array of REDValidationLists or component identifiers.
 * @param objects An array of REDValidationLists or component identifiers.
 * @return A modified validation list.
 */
- (REDValidationList *)and:(NSArray *)objects;

/*!
 * @brief Returns a validation list that ORs an array of lists or identifiers with the target list.
 * @warning @c objects @c must be an array of REDValidationLists or component identifiers.
 * @param objects An array of REDValidationLists or component identifiers.
 * @return A modified validation list.
 */
- (REDValidationList *)or:(NSArray *)objects;

/*!
 * @brief Validates a set of validation components.
 * @param components The validation components to be validated.
 * @param revalidate Whether the validation components should be revalidated or use their existing validation results.
 * @return The result of the validation.
 */
- (BOOL)validateComponents:(NSDictionary<id, REDValidationComponent *> *)components revalidate:(BOOL)revalidate;

@end
