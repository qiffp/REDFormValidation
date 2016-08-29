//
//  REDValidator.m
//  REDFormValidation
//
//  Created by Sam Dye on 2016-03-04.
//  Copyright © 2016 Sam Dye. All rights reserved.
//

#import "REDValidator.h"
#import "REDValidationComponent.h"
#import "REDValidatableComponent.h"
#import "REDValidationList.h"
#import "REDValidationList+Private.h"

@interface REDValidator () <REDValidationComponentDelegate>
@end

@implementation REDValidator {
	NSMutableDictionary<id, REDValidationComponent *> *_validationComponents;
}

- (instancetype)init
{
	self = [super init];
	if (self) {
		_shouldValidate = YES;
		_validationComponents = [NSMutableDictionary dictionary];
	}
	return self;
}

- (void)setValidationList:(REDValidationList *)validationList
{
	_validationList = validationList;
	[self evaluateComponents];
}

- (void)setComponent:(NSObject<REDValidatableComponent> *)component forValidation:(id)identifier
{
	REDValidationComponent *validationComponent = _validationComponents[identifier];
	[validationComponent reset];
	validationComponent.uiComponent = component;
	[self evaluateComponents];
}

- (BOOL)removeValidation:(id)identifier
{
	if (_validationComponents[identifier].validatedInValidationList) {
		return NO;
	} else {
		[_validationComponents removeObjectForKey:identifier];
		return YES;
	}
}

- (void)setShouldValidate:(BOOL)shouldValidate forValidation:(id)identifier
{
	_validationComponents[identifier].shouldValidate = shouldValidate;
}

- (void)addValidation:(id)identifier validateOn:(REDValidationEvent)event rule:(id<REDValidationRule>)rule;
{
	REDValidationComponent *validationComponent = [[REDValidationComponent alloc] initWithValidationEvent:event rule:rule];
	validationComponent.delegate = self;
	_validationComponents[identifier] = validationComponent;
	[self evaluateComponents];
}

- (REDValidationResult)valid
{
	return [self revalidate:NO];
}

- (REDValidationResult)validate
{
	return _shouldValidate ? [self revalidate:YES] : REDValidationResultValid;
}

- (REDValidationResult)revalidate:(BOOL)revalidate
{
	REDValidationResult result = [self revalidateValidationList:revalidate];
	
	for (REDValidationComponent *component in _validationComponents.allValues) {
		if (component.validatedInValidationList == NO) {
			result &= revalidate ? [component validate] : component.valid;
			if (result == 0) {
				result = REDValidationResultInvalid;
				break;
			}
		}
	}
	
	if ([_delegate respondsToSelector:@selector(validator:didValidateFormWithResult:)]) {
		[_delegate validator:self didValidateFormWithResult:result];
	}
	
	return result;
}

#pragma mark - Helpers

- (void)evaluateComponents
{
	[_validationList evaluateComponents:_validationComponents];
	[self evaluateDefaultValidity];
}

- (REDValidationResult)revalidateValidationList:(BOOL)revalidate
{
	if (_validationList == nil) {
		return REDValidationResultValid;
	}
	
	BOOL result = [_validationList validateComponents:_validationComponents revalidate:revalidate];
	return result ? REDValidationResultValid : REDValidationResultInvalid;
}

- (void)evaluateDefaultValidity
{
	for (REDValidationComponent *validationComponent in _validationComponents.allValues) {
		[validationComponent evaluateDefaultValidity];
	}
}

#pragma mark - REDValidationComponentDelegate

- (void)validationComponent:(REDValidationComponent *)validationComponent willValidateUIComponent:(NSObject<REDValidatableComponent> *)uiComponent
{
	if ([_delegate respondsToSelector:@selector(validator:willValidateComponent:)]) {
		[_delegate validator:self willValidateComponent:uiComponent];
	}
	
	if ([uiComponent respondsToSelector:@selector(validatorWillValidateComponent:)]) {
		[uiComponent validatorWillValidateComponent:self];
	}
}

- (void)validationComponent:(REDValidationComponent *)validationComponent didValidateUIComponent:(NSObject<REDValidatableComponent> *)uiComponent result:(REDValidationResult)result
{
	if ([_delegate respondsToSelector:@selector(validator:didValidateComponent:result:)]) {
		[_delegate validator:self didValidateComponent:uiComponent result:result];
	}
	
	if ([uiComponent respondsToSelector:@selector(validator:didValidateComponentWithResult:)]) {
		[uiComponent validator:self didValidateComponentWithResult:result];
	}
	
	[self revalidate:NO];
}

@end
