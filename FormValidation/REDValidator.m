//
//  REDValidator.m
//  REDFormValidation
//
//  Created by Sam Dye on 2016-03-04.
//  Copyright © 2016 Sam Dye. All rights reserved.
//

#import "REDValidator.h"
#import "REDValidation+Private.h"
#import "REDValidatableComponent.h"
#import "REDValidationTree+Private.h"
#import "REDValidationRuleType.h"

@interface REDValidator () <REDValidationDelegate>
@end

@implementation REDValidator {
	NSMutableDictionary<id, REDValidation *> *_validations;
	NSMutableDictionary<NSString *, id> *_uiComponents;
	
	dispatch_block_t _delayedValidationBlock;
	REDValidation *_firstResponderValidation;
}

- (instancetype)init
{
	self = [super init];
	if (self) {
		_shouldValidate = YES;
		_validations = [NSMutableDictionary new];
		_uiComponents = [NSMutableDictionary new];
	}
	return self;
}

- (void)setValidationTree:(REDValidationTree *)validationTree
{
	_validationTree = validationTree;
	[self evaluateValidations];
}

- (void)setShouldValidate:(BOOL)shouldValidate
{
	_shouldValidate = shouldValidate; // should this be before or after setting all of the validations?
	for (REDValidation *validation in _validations.allValues) {
		validation.shouldValidate = shouldValidate;
	}
	
	[self revalidate:NO notifyDelegate:YES];
}

- (NSDictionary<id, REDValidation *> *)validations
{
	return [_validations copy];
}

- (BOOL)removeValidationWithIdentifier:(id)identifier
{
	if (_validations[identifier].validatedInValidationTree) {
		return NO;
	} else {
		[_validations removeObjectForKey:identifier];
		return YES;
	}
}

- (void)addValidation:(REDValidation *)validation
{
	validation.delegate = self;
	_validations[validation.identifier] = validation;
	[self evaluateValidation:validation];
}

- (REDValidationResult)valid
{
	return [self revalidate:NO notifyDelegate:_shouldValidate];
}

- (REDValidationResult)validate
{
	return [self revalidate:YES notifyDelegate:_shouldValidate];
}

- (REDValidationResult)revalidate:(BOOL)revalidate notifyDelegate:(BOOL)notifyDelegate
{
	if (_shouldValidate == NO) {
		return REDValidationResultValid;
	}
	
	REDValidationResult result = [self revalidateValidationTree:revalidate];
	
	for (REDValidation *validation in _validations.allValues) {
		if (validation.validatedInValidationTree == NO) {
			result |= revalidate ? [validation validate] : validation.valid;
		}
	}
	
	result = [REDValidationTree resultForMask:result operation:REDValidationOperationAND];
	
	if ([_delegate respondsToSelector:@selector(validator:didValidateFormWithResult:)]) {
		[_delegate validator:self didValidateFormWithResult:result];
	}
	
	return result;
}

#pragma mark - Helpers

- (void)evaluateValidation:(REDValidation *)validation
{
	[_validationTree evaluateValidations:@{ validation.identifier : validation }];
	[self evaluateDefaultValidity:@[validation]];
}

- (void)evaluateValidations
{
	[_validationTree evaluateValidations:_validations];
	[self evaluateDefaultValidity];
}

- (REDValidationResult)revalidateValidationTree:(BOOL)revalidate
{
	if (_validationTree == nil) {
		return REDValidationResultValid;
	}
	
	return [_validationTree validateValidations:_validations revalidate:revalidate];
}

- (void)evaluateDefaultValidity
{
	[self evaluateDefaultValidity:_validations.allValues];
}

- (void)evaluateDefaultValidity:(NSArray<REDValidation *> *)validations
{
	for (REDValidation *validation in validations) {
		[validation evaluateDefaultValidity];
	}
}

#pragma mark - REDValidationDelegate

- (void)validation:(REDValidation *)validation didUpdateWithUIComponent:(NSObject<REDValidatableComponent> *)uiComponent
{
	if (uiComponent) {
		NSString *uiComponentAddress = [NSString stringWithFormat:@"%p", uiComponent];
		id validationIdentifier = _uiComponents[uiComponentAddress];
		if (validationIdentifier) {
			_validations[validationIdentifier].uiComponent = nil;
		}
		
		_uiComponents[uiComponentAddress] = validation.identifier;
	}
	
	[self evaluateValidation:validation];
}

- (void)validationUIComponentDidReceiveInput:(REDValidation *)validation
{
	if (_shouldValidate) {
		if (_delayedValidationBlock) {
			dispatch_block_cancel(_delayedValidationBlock);
		}
		
		_firstResponderValidation = validation;
		_delayedValidationBlock = dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS, ^{
			[_firstResponderValidation validate];
		});
		
		NSTimeInterval delay = [validation.rule isKindOfClass:[REDValidationRule class]] ? _inputDelay : _networkInputDelay;
		if (delay > 0.0) {
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), _delayedValidationBlock);
		} else {
			[_firstResponderValidation validate];
		}
	}
}

- (void)validationUIComponentDidEndEditing:(REDValidation *)validation
{
	_firstResponderValidation = nil;
	if (_delayedValidationBlock) {
		dispatch_block_cancel(_delayedValidationBlock);
		_delayedValidationBlock = nil;
	}
}

- (void)validation:(REDValidation *)validation willValidateUIComponent:(NSObject<REDValidatableComponent> *)uiComponent
{
	if (_shouldValidate) {
		if ([_delegate respondsToSelector:@selector(validator:willValidateUIComponent:)]) {
			[_delegate validator:self willValidateUIComponent:uiComponent];
		}
		
		if ([uiComponent respondsToSelector:@selector(validatorWillValidateUIComponent:)]) {
			[uiComponent validatorWillValidateUIComponent:self];
		}
	}
}

- (void)validation:(REDValidation *)validation didValidateUIComponent:(NSObject<REDValidatableComponent> *)uiComponent result:(REDValidationResult)result error:(NSError *)error
{
	if (_shouldValidate) {
		if ([_delegate respondsToSelector:@selector(validator:didValidateUIComponent:result:error:)]) {
			[_delegate validator:self didValidateUIComponent:uiComponent result:result error:error];
		}
		
		if ([uiComponent respondsToSelector:@selector(validator:didValidateUIComponentWithResult:error:)]) {
			[uiComponent validator:self didValidateUIComponentWithResult:result error:error];
		}
	}
	
	[self revalidate:NO notifyDelegate:_shouldValidate];
}

@end
