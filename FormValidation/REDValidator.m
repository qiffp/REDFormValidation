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

@interface REDValidator () <REDValidationComponentDelegate>
@end

@implementation REDValidator {
	NSMutableDictionary<NSNumber *, REDValidationComponent *> *_validationComponents;
	
	REDValidationBlock _validationBlock;
	BOOL _evaluatingBlock;
	BOOL _revalidatingComponents;
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

- (void)setValidationBlock:(REDValidationBlock)validationBlock
{
	_validationBlock = [validationBlock copy];
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
	if (_validationComponents[identifier].validatedInValidatorBlock) {
		return NO;
	} else {
		[_validationComponents removeObjectForKey:identifier];
		return YES;
	}
}

- (void)setShouldValidate:(BOOL)shouldValidate forValidation:(id)identifier
{
	_validationComponents[identifier].shouldValidate = shouldValidate;
	[self validate];
}

- (void)addValidation:(id)identifier validateOn:(REDValidationEvent)event rule:(id<REDValidationRule>)rule;
{
	REDValidationComponent *validationComponent = [[REDValidationComponent alloc] initWithValidationEvent:event rule:rule];
	validationComponent.delegate = self;
	_validationComponents[identifier] = validationComponent;
	[self evaluateComponents];
}

- (BOOL)validationIsValid:(id)identifier
{
	if (_evaluatingBlock) {
		_validationComponents[identifier].validatedInValidatorBlock = YES;
		return NO;
	} else {
		REDValidationComponent *component = _validationComponents[identifier];
		REDValidationResult result = _revalidatingComponents ? [component validate] : component.valid;
		return result == REDValidationResultValid || result == REDValidationResultOptionalValid;
	}
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
	REDValidationResult result = [self executeValidationBlockAfter:^{
		_revalidatingComponents = revalidate;
	} completion:^{
		_revalidatingComponents = NO;
	}];
	
	for (REDValidationComponent *component in _validationComponents.allValues) {
		if (component.validatedInValidatorBlock == NO) {
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
	[self evaluateValidationBlock];
	[self evaluateOptionalValidity];
}

- (void)evaluateValidationBlock
{
	for (REDValidationComponent *validationComponent in _validationComponents.allValues) {
		validationComponent.validatedInValidatorBlock = NO;
	}
	
	[self executeValidationBlockAfter:^{
		_evaluatingBlock = YES;
	} completion:^{
		_evaluatingBlock = NO;
	}];
}

- (void)evaluateOptionalValidity
{
	for (REDValidationComponent *validationComponent in _validationComponents.allValues) {
		[validationComponent evaluateOptionalValidity];
	}
}

- (REDValidationResult)executeValidationBlockAfter:(void (^)())first completion:(void (^)())completion
{
	REDValidationResult result = REDValidationResultValid;
	
	if (first) {
		first();
	}
	
	if (_validationBlock) {
		result = _validationBlock(self) ? REDValidationResultValid : REDValidationResultInvalid;
	}
	
	if (completion) {
		completion();
	}
	
	return result;
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
