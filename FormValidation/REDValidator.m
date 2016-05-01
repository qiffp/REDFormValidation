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

static void *REDTableViewVisibleCellsChangedContext = &REDTableViewVisibleCellsChangedContext;

@interface REDValidator () <REDValidationComponentDelegate, UITableViewDelegate>
@end

@implementation REDValidator {
	NSMutableDictionary<NSNumber *, REDValidationComponent *> *_validationComponents;
	
	REDTableViewValidationBlock _validationBlock;
	BOOL _evaluatingBlock;
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

- (void)setComponent:(UIView *)component forValidation:(NSInteger)tag
{
	REDValidationComponent *validationComponent = _validationComponents[@(tag)];
	[validationComponent reset];
	validationComponent.uiComponent = component;
	[self evaluateValidationBlock];
}

- (BOOL)removeValidation:(NSInteger)tag
{
	if (_validationComponents[@(tag)].validatedInValidatorBlock) {
		return NO;
	} else {
		[_validationComponents removeObjectForKey:@(tag)];
		return YES;
	}
}

- (void)setShouldValidate:(BOOL)shouldValidate forValidation:(NSInteger)tag
{
	_validationComponents[@(tag)].shouldValidate = shouldValidate;
	[self validate];
}

- (void)addValidationWithTag:(NSInteger)tag validateOn:(REDValidationEvent)event rule:(id<REDValidationRule>)rule;
{
	REDValidationComponent *validationComponent = [[REDValidationComponent alloc] initWithValidationEvent:event rule:rule];
	validationComponent.delegate = self;
	_validationComponents[@(tag)] = validationComponent;
	[self evaluateValidationBlock];
}

- (BOOL)validationIsValid:(NSInteger)tag
{
	if (_evaluatingBlock) {
		_validationComponents[@(tag)].validatedInValidatorBlock = YES;
		return NO;
	} else {
		return _validationComponents[@(tag)].valid;
	}
}

- (BOOL)validate
{
	BOOL result = YES;
	if (_shouldValidate) {
		if (_validationBlock) {
			result = _validationBlock(self);
			
			for (REDValidationComponent *component in _validationComponents.allValues) {
				if (component.validatedInValidatorBlock == NO) {
					result &= component.valid;
				}
			}
		} else {
			for (REDValidationComponent *component in _validationComponents.allValues) {
				result &= component.valid;
			}
		}
		
		if ([_delegate respondsToSelector:@selector(validator:didValidateFormWithResult:)]) {
			[_delegate validator:self didValidateFormWithResult:result];
		}
	}
	
	_valid = result;
	
	return result;
}

#pragma mark - Helpers

- (void)evaluateValidationBlock
{
	for (REDValidationComponent *validationComponent in _validationComponents.allValues) {
		validationComponent.validatedInValidatorBlock = NO;
	}
	
	if (_validationBlock) {
		_evaluatingBlock = YES;
		_validationBlock(self);
		_evaluatingBlock = NO;
	}
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
	
	[self validate];
}

@end
