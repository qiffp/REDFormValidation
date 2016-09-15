//
//  REDValidationTree.m
//  REDFormValidation
//
//  Created by Sam Dye on 2016-08-22.
//  Copyright © 2016 Sam Dye. All rights reserved.
//

#import "REDValidationTree.h"
#import "REDValidationTree+Private.h"
#import "REDValidation.h"

@implementation REDValidationTree {
	NSNumber *_operation;
	NSArray *_identifiers;
	NSArray<REDValidationTree *> *_trees;
}

- (instancetype)initWithOperation:(REDValidationOperation)operation objects:(NSArray *)objects
{
	self = [super init];
	if (self) {
		_operation = @(operation);
		
		id obj = objects.firstObject;
		if ([obj isKindOfClass:[REDValidationTree class]]) {
			_trees = objects;
		} else {
			_identifiers = objects;
		}
	}
	return self;
}

+ (REDValidationTree *)single:(id)identifier
{
	return [[REDValidationTree alloc] initWithOperation:REDValidationOperationNone objects:@[identifier]];
}

+ (REDValidationTree *)and:(NSArray *)objects
{
	return [[REDValidationTree alloc] initWithOperation:REDValidationOperationAND objects:objects];
}

+ (REDValidationTree *)or:(NSArray *)objects
{
	return [[REDValidationTree alloc] initWithOperation:REDValidationOperationOR objects:objects];
}

- (REDValidationResult)validateValidations:(NSDictionary<id, REDValidation *> *)validations revalidate:(BOOL)revalidate
{
	if (_identifiers) {
		REDValidationResult result = [self validateValidations:validations withIdentifiers:_identifiers revalidate:revalidate];
		return [REDValidationTree resultForMask:result operation:_operation.unsignedIntegerValue];
	} else {
		REDValidationResult result = 0;
		
		for (REDValidationTree *tree in _trees) {
			result |= [tree validateValidations:validations revalidate:revalidate];
		}
		
		return [REDValidationTree resultForMask:result operation:_operation.unsignedIntegerValue];
	}
}

- (REDValidationResult)validateValidations:(NSDictionary<id, REDValidation *> *)validations withIdentifiers:(NSArray *)identifiers revalidate:(BOOL)revalidate
{
	REDValidationResult result = 0;
	
	for (id identifier in identifiers) {
		REDValidation *validation = validations[identifier];
		if (validation == nil) {
			NSLog(@"<REDFormValidation WARNING> Identifier '%@' used in the validation tree is not associated with a validation. This will always validate as REDValidationResultUnvalidated", identifier);
		}
		
		result |= revalidate ? [validation validate] : validation.valid;
	}
	
	return result;
}

- (void)evaluateValidations:(NSDictionary<id, REDValidation *> *)validations
{
	[self evaluateValidations:validations resetValues:YES];
}

- (void)evaluateValidations:(NSDictionary<id, REDValidation *> *)validations resetValues:(BOOL)resetValues
{
	if (resetValues) {
		for (REDValidation *validation in validations.allValues) {
			validation.validatedInValidationTree = NO;
		}
	}
	
	if (_identifiers) {
		for (id identifier in _identifiers) {
			validations[identifier].validatedInValidationTree = YES;
		}
	} else {
		for (REDValidationTree *tree in _trees) {
			[tree evaluateValidations:validations resetValues:NO];
		}
	}
}

+ (REDValidationResult)resultForMask:(REDValidationResult)mask operation:(REDValidationOperation)operation
{
	if (mask & REDValidationResultInvalid) {
		return REDValidationResultInvalid;
	} else if (mask & REDValidationResultPending) {
		return REDValidationResultPending;
	} else if (mask & REDValidationResultUnvalidated) {
		if (mask == REDValidationResultUnvalidated) {
			return REDValidationResultUnvalidated;
		} else {
			switch (operation) {
				case REDValidationOperationNone:
					return REDValidationResultUnvalidated;
					break;
				case REDValidationOperationAND:
					return REDValidationResultInvalid;
					break;
				default:
					return REDValidationResultValid;
					break;
			}
		}
	} else {
		return REDValidationResultValid;
	}
}

@end
