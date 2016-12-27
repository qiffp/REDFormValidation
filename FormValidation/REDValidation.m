//
//  REDValidation.m
//  REDFormValidation
//
//  Created by Sam Dye on 2016-03-04.
//  Copyright © 2016 Sam Dye. All rights reserved.
//

#import "REDValidation+Private.h"

@interface REDValidation () <REDNetworkValidationRuleDelegate, UITextFieldDelegate, UITextViewDelegate>
@end

@implementation REDValidation {
	REDValidationEvent _event;
	BOOL _requiresValidation;
}

@synthesize delegate = _delegate;
@synthesize validatedInValidationTree = _validatedInValidationTree;
@synthesize rule = _rule;
@synthesize initialValue = _initialValue;
@synthesize allowDefault = _allowDefault;
@synthesize identifier = _identifier;

+ (instancetype)validationWithIdentifier:(id)identifier rule:(id<REDValidationRuleType>)rule
{
	return [self validationWithIdentifier:identifier initialValue:nil allowDefault:NO validationEvent:REDValidationEventDefault rule:rule];
}

+ (instancetype)validationWithIdentifier:(id)identifier initialValue:(id)initialValue allowDefault:(BOOL)allowDefault validationEvent:(REDValidationEvent)event rule:(id<REDValidationRuleType>)rule
{
	return [[self alloc] initWithIdentifier:identifier initialValue:initialValue allowDefault:allowDefault validationEvent:event rule:rule];
}

- (instancetype)initWithIdentifier:(id)identifier initialValue:(id)initialValue allowDefault:(BOOL)allowDefault validationEvent:(REDValidationEvent)event rule:(id<REDValidationRuleType>)rule
{
	self = [super init];
	if (self ) {
		_valid = REDValidationResultUnvalidated;
		_shouldValidate = YES;
		_identifier = [identifier copy];
		_initialValue = [initialValue copy];
		_allowDefault = allowDefault;
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
	
	[self removeUIComponentEventActions];
	_uiComponent = uiComponent;
	[self setupUIComponentEventActions];
	
	[_delegate validation:self didUpdateWithUIComponent:uiComponent];
}

- (void)setShouldValidate:(BOOL)shouldValidate
{
	if (_shouldValidate == shouldValidate) {
		return;
	}
	
	_shouldValidate = shouldValidate;
	[self validate];
}

- (void)removeUIComponentEventActions
{
	if ([_uiComponent isKindOfClass:[UITextField class]] || [_uiComponent isKindOfClass:[UITextView class]]) {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:_uiComponent];
	} else if ([_uiComponent isKindOfClass:[UIControl class]]) {
		[(UIControl *)_uiComponent removeTarget:self action:nil forControlEvents:UIControlEventAllEvents];
	}
}

- (void)setupUIComponentEventActions
{
	if ([_uiComponent isKindOfClass:[UITextField class]]) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uiComponentTextDidChange:) name:UITextFieldTextDidChangeNotification object:_uiComponent];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uiComponentTextDidEndEditing:) name:UITextFieldTextDidEndEditingNotification object:_uiComponent];
	} else if ([_uiComponent isKindOfClass:[UITextView class]]) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uiComponentTextDidChange:) name:UITextViewTextDidChangeNotification object:_uiComponent];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uiComponentTextDidEndEditing:) name:UITextViewTextDidEndEditingNotification object:_uiComponent];
	} else if ([_uiComponent isKindOfClass:[UIControl class]]) {
		UIControl *component = (UIControl *)_uiComponent;
		[component addTarget:self action:@selector(validatableComponentValueChanged:) forControlEvents:UIControlEventValueChanged];
		[component addTarget:self action:@selector(validatableComponentDidEndEditing:) forControlEvents:UIControlEventEditingDidEnd];
	}
}

- (REDValidationResult)validate
{
	[_delegate validation:self willValidateUIComponent:_uiComponent];
	
	_requiresValidation = NO;
	
	if (_shouldValidate) {
		REDValidationResult result = _valid;
		
		if (_uiComponent) {
			result = [_rule validate:_uiComponent allowDefault:_allowDefault];
		} else if (_initialValue && _valid == REDValidationResultUnvalidated) {
			result = [_rule validateValue:_initialValue];
		}
		
		_valid = result;
		
		if ([_rule isKindOfClass:[REDNetworkValidationRule class]] == NO) {
			[_delegate validation:self didValidateUIComponent:_uiComponent result:_valid error:nil];
		}
	} else {
		_valid = REDValidationResultValid;
		[_delegate validation:self didValidateUIComponent:_uiComponent result:_valid error:nil];
	}
	
	return _valid;
}

- (REDValidationResult)evaluateDefaultValidity
{
	if (_allowDefault && (_uiComponent == nil || [_uiComponent.validatedValue isEqual:_uiComponent.defaultValue])) {
		_valid = REDValidationResultDefaultValid;
	}
	
	return _valid;
}

#pragma mark - Helpers

- (void)uiComponentValueChanged
{
	_requiresValidation = YES;
	if (_event == REDValidationEventDefault) {
		[_delegate validationUIComponentDidReceiveInput:self];
	}
}

- (void)uiComponentDidEndEditing
{
	if (_requiresValidation) {
		[self validate];
	}
	[_delegate validationUIComponentDidEndEditing:self];
}

#pragma mark - Actions

- (void)validatableComponentValueChanged:(NSObject<REDValidatableComponent> *)component
{
	[self uiComponentValueChanged];
}

- (void)validatableComponentDidEndEditing:(NSObject<REDValidatableComponent> *)component
{
	[self uiComponentDidEndEditing];
}

#pragma mark - Notifications

- (void)uiComponentTextDidChange:(NSNotification *)notification
{
	[self uiComponentValueChanged];
}

- (void)uiComponentTextDidEndEditing:(NSNotification *)notification
{
	[self uiComponentDidEndEditing];
}

#pragma mark - NetworkValidationRuleDelegate

- (void)validationRule:(id<REDValidationRuleType>)rule completedNetworkValidationOfUIComponent:(NSObject<REDValidatableComponent> *)uiComponent withResult:(REDValidationResult)result error:(NSError *)error
{
	_valid = result;
	[_delegate validation:self didValidateUIComponent:uiComponent result:result error:error];
}

@end
