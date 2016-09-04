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
#import "REDValidationTree.h"
#import "REDValidationTree+Private.h"

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

- (void)setValidationTree:(REDValidationTree *)validationTree
{
	_validationTree = validationTree;
	[self evaluateComponents];
}

- (void)setComponent:(NSObject<REDValidatableComponent> *)component forValidation:(id)identifier
{
	REDValidationComponent *validationComponent = _validationComponents[identifier];
	if (validationComponent) {
		validationComponent.uiComponent = component;
		[self evaluateComponent:validationComponent identifier:identifier];
	}
}

- (BOOL)removeValidation:(id)identifier
{
	if (_validationComponents[identifier].validatedInValidationTree) {
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

- (void)addValidation:(id)identifier validateOn:(REDValidationEvent)event rule:(id<REDValidationRuleType>)rule;
{
	[self addValidation:identifier initialValue:nil validateOn:event rule:rule];
}

- (void)addValidation:(id)identifier initialValue:(id)initialValue validateOn:(REDValidationEvent)event rule:(id<REDValidationRuleType>)rule;
{
	REDValidationComponent *validationComponent = [[REDValidationComponent alloc] initWithInitialValue:initialValue validationEvent:event rule:rule];
	validationComponent.delegate = self;
	_validationComponents[identifier] = validationComponent;
	[self evaluateComponent:validationComponent identifier:identifier];
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
	REDValidationResult result = [self revalidateValidationTree:revalidate];
	
	for (REDValidationComponent *component in _validationComponents.allValues) {
		if (component.validatedInValidationTree == NO) {
			result |= revalidate ? [component validate] : component.valid;
		}
	}
	
	result = [REDValidationTree resultForMask:result operation:REDValidationOperationAND];
	
	if ([_delegate respondsToSelector:@selector(validator:didValidateFormWithResult:)]) {
		[_delegate validator:self didValidateFormWithResult:result];
	}
	
	return result;
}

#pragma mark - Helpers

- (void)evaluateComponent:(REDValidationComponent *)component identifier:(id)identifier
{
	[_validationTree evaluateComponents:@{ identifier : component }];
	[self evaluateDefaultValidity:@[component]];
}

- (void)evaluateComponents
{
	[_validationTree evaluateComponents:_validationComponents];
	[self evaluateDefaultValidity];
}

- (REDValidationResult)revalidateValidationTree:(BOOL)revalidate
{
	if (_validationTree == nil) {
		return REDValidationResultValid;
	}
	
	return [_validationTree validateComponents:_validationComponents revalidate:revalidate];
}

- (void)evaluateDefaultValidity
{
	[self evaluateDefaultValidity:_validationComponents.allValues];
}

- (void)evaluateDefaultValidity:(NSArray<REDValidationComponent *> *)components
{
	for (REDValidationComponent *validationComponent in components) {
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

- (void)validationComponent:(REDValidationComponent *)validationComponent didValidateUIComponent:(NSObject<REDValidatableComponent> *)uiComponent result:(REDValidationResult)result error:(NSError *)error
{
	if ([_delegate respondsToSelector:@selector(validator:didValidateComponent:result:error:)]) {
		[_delegate validator:self didValidateComponent:uiComponent result:result error:error];
	}
	
	if ([uiComponent respondsToSelector:@selector(validator:didValidateComponentWithResult:error:)]) {
		[uiComponent validator:self didValidateComponentWithResult:result error:error];
	}
	
	[self revalidate:NO];
}

@end
