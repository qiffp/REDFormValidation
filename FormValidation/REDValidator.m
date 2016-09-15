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
#import "REDValidationRuleType.h"

@interface REDValidator () <REDValidationComponentDelegate>
@end

@implementation REDValidator {
	NSMutableDictionary<id, REDValidationComponent *> *_validationComponents;
	
	dispatch_block_t _delayedValidationBlock;
	REDValidationComponent *_firstResponderComponent;
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

- (NSDictionary<id, REDValidationComponent *> *)validationComponents
{
	return [_validationComponents copy];
}

- (BOOL)removeValidationWithIdentifier:(id)identifier
{
	if (_validationComponents[identifier].validatedInValidationTree) {
		return NO;
	} else {
		[_validationComponents removeObjectForKey:identifier];
		return YES;
	}
}

- (void)addValidation:(REDValidationComponent *)validationComponent
{
	validationComponent.delegate = self;
	_validationComponents[validationComponent.identifier] = validationComponent;
	[self evaluateComponent:validationComponent];
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

- (void)evaluateComponent:(REDValidationComponent *)component
{
	[_validationTree evaluateComponents:@{ component.identifier : component }];
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

- (void)validationComponentDidUpdateUIComponent:(REDValidationComponent *)validationComponent
{
	[self evaluateComponent:validationComponent];
}

- (void)validationComponentDidReceiveInput:(REDValidationComponent *)validationComponent
{
	if (_delayedValidationBlock) {
		dispatch_block_cancel(_delayedValidationBlock);
	}
	
	_firstResponderComponent = validationComponent;
	_delayedValidationBlock = dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS, ^{
		[_firstResponderComponent validate];
	});
	
	NSTimeInterval delay = [validationComponent.rule isKindOfClass:[REDValidationRule class]] ? _inputDelay : _networkInputDelay;
	if (delay > 0.0) {
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), _delayedValidationBlock);
	} else {
		[_firstResponderComponent validate];
	}
}

- (void)validationComponentDidEndEditing:(REDValidationComponent *)validationComponent
{
	_firstResponderComponent = nil;
	if (_delayedValidationBlock) {
		dispatch_block_cancel(_delayedValidationBlock);
		_delayedValidationBlock = nil;
	}
}

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
