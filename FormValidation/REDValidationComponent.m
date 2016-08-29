//
//  REDValidationComponent.m
//  REDFormValidation
//
//  Created by Sam Dye on 2016-03-04.
//  Copyright © 2016 Sam Dye. All rights reserved.
//

#import "REDValidationComponent.h"

@interface NSObject (Control)
- (BOOL)isNonTextControlClass;
@end

@interface REDValidationComponent () <REDNetworkValidationRuleDelegate, UITextFieldDelegate, UITextViewDelegate>
@end

@implementation REDValidationComponent {
	id<REDValidationRule> _rule;
	struct {
		BOOL change;
		BOOL beginEditing;
		BOOL endEditing;
	} _validationEvents;
	
	REDValidationResult _valid;
}

- (instancetype)init
{
	return [self initWithInitialValue:nil validationEvent:REDValidationEventAll rule:nil];
}

- (instancetype)initWithInitialValue:(id)initialValue validationEvent:(REDValidationEvent)event rule:(id<REDValidationRule>)rule
{
	self = [super init];
	if (self ) {
		[self reset];
		_shouldValidate = YES;
		_initialValue = initialValue;
		
		if (event & REDValidationEventAll) {
			_validationEvents.change = YES;
			_validationEvents.beginEditing = YES;
			_validationEvents.endEditing = YES;
		} else {
			_validationEvents.change = event & REDValidationEventChange;
			_validationEvents.beginEditing = event & REDValidationEventBeginEditing;
			_validationEvents.endEditing = event & REDValidationEventEndEditing;
		}
		
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
	} else if ([_uiComponent isNonTextControlClass]) {
		[(UIControl *)_uiComponent removeTarget:self action:nil forControlEvents:UIControlEventAllEvents];
	}
}

- (void)setupComponentEventActions
{
	if ([_uiComponent isKindOfClass:[UITextField class]]) {
		if (_validationEvents.change) {
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:UITextFieldTextDidChangeNotification object:_uiComponent];
		}
		if (_validationEvents.beginEditing) {
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidBeginEditing:) name:UITextFieldTextDidBeginEditingNotification object:_uiComponent];
		}
		if (_validationEvents.endEditing) {
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidEndEditing:) name:UITextFieldTextDidEndEditingNotification object:_uiComponent];
		}
	} else if ([_uiComponent isKindOfClass:[UITextView class]]) {
		if (_validationEvents.change) {
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:UITextViewTextDidChangeNotification object:_uiComponent];
		}
		if (_validationEvents.beginEditing) {
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidBeginEditing:) name:UITextViewTextDidBeginEditingNotification object:_uiComponent];
		}
		if (_validationEvents.endEditing) {
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidEndEditing:) name:UITextViewTextDidEndEditingNotification object:_uiComponent];
		}
	} else if ([_uiComponent isNonTextControlClass]) {
		UIControl *component = (UIControl *)_uiComponent;
		if (_validationEvents.change) {
			[component addTarget:self action:@selector(componentValueChanged:) forControlEvents:UIControlEventValueChanged];
		}
		if (_validationEvents.beginEditing) {
			[component addTarget:self action:@selector(componentDidBeginEditing:) forControlEvents:UIControlEventEditingDidBegin];
		}
		if (_validationEvents.endEditing) {
			[component addTarget:self action:@selector(componentDidEndEditing:) forControlEvents:UIControlEventEditingDidEnd];
		}
	}
}

- (REDValidationResult)validate
{
	[_delegate validationComponent:self willValidateUIComponent:_uiComponent];
	
	if (!_shouldValidate) {
		_valid = REDValidationResultValid;
		[_delegate validationComponent:self didValidateUIComponent:_uiComponent result:_valid];
	} else {
		REDValidationResult result = _valid;
		
		if (_uiComponent) {
			result = [_rule validate:_uiComponent];
		} else if (_initialValue && _valid == REDValidationResultUnvalidated) {
			result = [_rule validateValue:_initialValue];
		}
		
		_valid = result;
		
		if ([_rule isKindOfClass:[REDNetworkValidationRule class]] == NO) {
			[_delegate validationComponent:self didValidateUIComponent:_uiComponent result:_valid];
		}
	}
	
	return _valid;
}

- (void)reset
{
	_valid = REDValidationResultUnvalidated;
}

- (REDValidationResult)evaluateDefaultValidity
{
	if (_valid == REDValidationResultUnvalidated && _rule.allowDefault && (_uiComponent == nil || [[_uiComponent validatedValue] isEqual:[_uiComponent defaultValue]])) {
		_valid = REDValidationResultDefaultValid;
	}
	
	return _valid;
}

#pragma mark - Actions

- (void)componentValueChanged:(NSObject<REDValidatableComponent> *)component
{
	[self validate];
}

- (void)componentDidBeginEditing:(NSObject<REDValidatableComponent> *)component
{
	[self validate];
}

- (void)componentDidEndEditing:(NSObject<REDValidatableComponent> *)component
{
	[self validate];
}

#pragma mark - Notifications

- (void)textDidChange:(NSNotification *)notification
{
	[self validate];
}

- (void)textDidBeginEditing:(NSNotification *)notification
{
	[self validate];
}

- (void)textDidEndEditing:(NSNotification *)notification
{
	[self validate];
}

#pragma mark - NetworkValidationRuleDelegate

- (void)validationRule:(id<REDValidationRule>)rule completedNetworkValidationOfComponent:(NSObject<REDValidatableComponent> *)component withResult:(REDValidationResult)result error:(NSError *)error
{
	_valid = result;
	[_delegate validationComponent:self didValidateUIComponent:component result:result];
}

@end

@implementation UIView (Control)

- (BOOL)isNonTextControlClass
{
	return [self isKindOfClass:[UIControl class]] && !([self isKindOfClass:[UITextField class]] || [self isKindOfClass:[UITextView class]]);
}

@end
