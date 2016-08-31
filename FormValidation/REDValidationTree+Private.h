//
//  REDValidationTree+Private.h
//  REDFormValidation
//
//  Created by Sam Dye on 2016-08-29.
//  Copyright © 2016 Sam Dye. All rights reserved.
//

@interface REDValidationTree (Private)

/*!
 * @brief Evaluates whether the tree uses the given validation components.
 * @discussion Should not be used.
 * @param components The validation components to be evaluated.
 */
- (void)evaluateComponents:(NSDictionary<id, REDValidationComponent *> *)components;

@end