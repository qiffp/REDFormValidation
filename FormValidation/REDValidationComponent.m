//
//  REDValidationComponent.m
//  REDFormValidation
//
//  Created by Sam Dye on 2016-03-04.
//  Copyright © 2016 Sam Dye. All rights reserved.
//

#import "REDValidationComponent.h"

@interface REDValidationComponent () <REDNetworkValidationRuleDelegate, UITextFieldDelegate, UITextViewDelegate>
@end

@implementation REDValidationComponent {
	REDValidationEvent _event;
}

- (instancetype)initWithIdentifier:(id)identifier rule:(id<REDValidationRuleType>)rule
{
	return [self initWithIdentifier:identifier initialValue:nil validationEvent:REDValidationEventDefault rule:rule];
}

- (instancetype)initWithIdentifier:(id)identifier initialValue:(id)initialValue validationEvent:(REDValidationEvent)event rule:(id<REDValidationRuleType>)rule
{
	self = [super init];
	if (self ) {
		_valid = REDValidationResultUnvalidated;
		_shouldValidate = YES;
		_identifier = [identifier copy];
		_initialValue = [initialValue copy];
		_event = event;
		
		_rule = rule;
		if ([_rule isKindOfClass:[REDNetworkValidationRule class]]) {
			((REDNetworkValidationRule *)_rule).delegate = self;
		}
	}
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setUiComponent:(NSObject<REDValidatableComponent> *)uiComponent
{
	if (_uiComponent == uiComponent) {
		return;
	}
	
	[self removeComponentEventActions];
	_uiComponent = uiComponent;
	[self setupComponentEventActions];
	
	[_delegate validationComponentDidUpdateUIComponent:self];
}

- (void)setShouldValidate:(BOOL)shouldValidate
{
	if (_shouldValidate == shouldValidate) {
		return;
	}
	
	_shouldValidate = shouldValidate;
	[self validate];
}

- (void)removeComponentEventActions
{
	if ([_uiComponent isKindOfClass:[UITextField class]] || [_uiComponent isKindOfClass:[UITextView class]]) {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:_uiComponent];
	} else if ([_uiComponent isKindOfClass:[UIControl class]]) {
		[(UIControl *)_uiComponent removeTarget:self action:nil forControlEvents:UIControlEventAllEvents];
	}
}

- (void)setupComponentEventActions
{
	if ([_uiComponent isKindOfClass:[UITextField class]]) {
		if (_event == REDValidationEventDefault) {
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:UITextFieldTextDidChangeNotification object:_uiComponent];
		}
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidEndEditing:) name:UITextFieldTextDidEndEditingNotification object:_uiComponent];
	} else if ([_uiComponent isKindOfClass:[UITextView class]]) {
		if (_event == REDValidationEventDefault) {
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:UITextViewTextDidChangeNotification object:_uiComponent];
		}
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidEndEditing:) name:UITextViewTextDidEndEditingNotification object:_uiComponent];
	} else if ([_uiComponent isKindOfClass:[UIControl class]]) {
		UIControl *component = (UIControl *)_uiComponent;
		if (_event == REDValidationEventDefault) {
			[component addTarget:self action:@selector(componentValueChanged:) forControlEvents:UIControlEventValueChanged];
		}
		[component addTarget:self action:@selector(componentDidEndEditing:) forControlEvents:UIControlEventEditingDidEnd];
	}
}

- (REDValidationResult)validate
{
	[_delegate validationComponent:self willValidateUIComponent:_uiComponent];
	
	if (_shouldValidate) {
		REDValidationResult result = _valid;
		
		if (_uiComponent) {
			result = [_rule validate:_uiComponent];
		} else if (_initialValue && _valid == REDValidationResultUnvalidated) {
			result = [_rule validateValue:_initialValue];
		}
		
		_valid = result;
		
		if ([_rule isKindOfClass:[REDNetworkValidationRule class]] == NO) {
			[_delegate validationComponent:self didValidateUIComponent:_uiComponent result:_valid error:nil];
		}
	} else {
		_valid = REDValidationResultValid;
		[_delegate validationComponent:self didValidateUIComponent:_uiComponent result:_valid error:nil];
	}
	
	return _valid;
}

- (REDValidationResult)evaluateDefaultValidity
{
	if (_rule.allowDefault && (_uiComponent == nil || [[_uiComponent validatedValue] isEqual:[_uiComponent defaultValue]])) {
		_valid = REDValidationResultDefaultValid;
	}
	
	return _valid;
}

#pragma mark - Actions

- (void)componentValueChanged:(NSObject<REDValidatableComponent> *)component
{
	[_delegate validationComponentDidReceiveInput:self];
}

- (void)componentDidEndEditing:(NSObject<REDValidatableComponent> *)component
{
	[self validate];
	[_delegate validationComponentDidEndEditing:self];
}

#pragma mark - Notifications

- (void)textDidChange:(NSNotification *)notification
{
	[_delegate validationComponentDidReceiveInput:self];
}

- (void)textDidEndEditing:(NSNotification *)notification
{
	[self validate];
	[_delegate validationComponentDidEndEditing:self];
}

#pragma mark - NetworkValidationRuleDelegate

- (void)validationRule:(id<REDValidationRuleType>)rule completedNetworkValidationOfComponent:(NSObject<REDValidatableComponent> *)component withResult:(REDValidationResult)result error:(NSError *)error
{
	_valid = result;
	[_delegate validationComponent:self didValidateUIComponent:component result:result error:error];
}

@end
