//
//  REDValidator.m
//  REDFormValidation
//
//  Created by Sam Dye on 2016-03-04.
//  Copyright © 2016 Sam Dye. All rights reserved.
//

#import "REDValidator.h"
#import "REDValidationRule.h"
#import "REDValidationComponent.h"

@interface REDValidator () <REDValidationComponentDelegate, UITableViewDelegate>
@end

@implementation REDValidator {
	NSMutableDictionary<NSNumber *, REDValidationComponent *> *_validationComponents;
	
	REDTableViewValidationBlock _validationBlock;
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

- (void)setValidationBlock:(REDTableViewValidationBlock)validationBlock
{
	_validationBlock = [validationBlock copy];
	[self evaluateValidationBlock];
}

- (void)setComponent:(UIView *)component forValidation:(id)identifier
{
	REDValidationComponent *validationComponent = _validationComponents[identifier];
	[validationComponent reset];
	validationComponent.uiComponent = component;
	[self evaluateValidationBlock];
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
	[self evaluateValidationBlock];
}

- (BOOL)validationIsValid:(id)identifier
{
	if (_evaluatingBlock) {
		_validationComponents[identifier].validatedInValidatorBlock = YES;
		return NO;
	} else {
		REDValidationComponent *component = _validationComponents[identifier];
		return _revalidatingComponents ? [component validate] : component.valid;
	}
}

- (BOOL)valid
{
	return [self revalidate:NO];
}

- (BOOL)validate
{
	return _shouldValidate ? [self revalidate:YES] : YES;
}

- (BOOL)revalidate:(BOOL)revalidate
{
	BOOL result = [self executeValidationBlockAfter:^{
		_revalidatingComponents = revalidate;
	} completion:^{
		_revalidatingComponents = NO;
	}];
	
	for (REDValidationComponent *component in _validationComponents.allValues) {
		if (component.validatedInValidatorBlock == NO) {
			result &= revalidate ? [component validate] : component.valid;
		}
	}
	
	if ([_delegate respondsToSelector:@selector(validator:didValidateFormWithResult:)]) {
		[_delegate validator:self didValidateFormWithResult:result];
	}
	
	return result;
}

#pragma mark - Helpers

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

- (BOOL)executeValidationBlockAfter:(void (^)())first completion:(void (^)())completion
{
	BOOL result = YES;
	
	if (first) {
		first();
	}
	
	if (_validationBlock) {
		result = _validationBlock(self);
	}
	
	if (completion) {
		completion();
	}
	
	return result;
}

#pragma mark - REDValidationComponentDelegate

- (void)validationComponent:(REDValidationComponent *)validationComponent willValidateUIComponent:(UIView *)uiComponent
{
	if ([_delegate respondsToSelector:@selector(validator:willValidateComponent:)]) {
		[_delegate validator:self willValidateComponent:uiComponent];
	}
	
	if ([uiComponent respondsToSelector:@selector(validatorWillValidateComponent:)]) {
		[(id<REDValidatorComponent>)uiComponent validatorWillValidateComponent:self];
	}
}

- (void)validationComponent:(REDValidationComponent *)validationComponent didValidateUIComponent:(UIView *)uiComponent result:(BOOL)result
{
	if ([_delegate respondsToSelector:@selector(validator:didValidateComponent:result:)]) {
		[_delegate validator:self didValidateComponent:uiComponent result:result];
	}
	
	if ([uiComponent respondsToSelector:@selector(validator:didValidateComponentWithResult:)]) {
		[(id<REDValidatorComponent>)uiComponent validator:self didValidateComponentWithResult:result];
	}
	
	[self revalidate:NO];
}

@end
