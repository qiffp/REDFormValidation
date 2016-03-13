//
//  REDValidationComponent.m
//  REDFormValidation
//
//  Created by Sam Dye on 2016-03-04.
//  Copyright © 2016 Sam Dye. All rights reserved.
//

#import "REDValidationComponent.h"

#import "REDValidationRule.h"

@interface UIView (Control)
- (BOOL)isNonTextControlClass;
@end

@interface REDValidationComponent () <REDNetworkValidationRuleDelegate, UITextFieldDelegate, UITextViewDelegate>
@end

@implementation REDValidationComponent {
	struct {
		unsigned int change:1;
		unsigned int beginEditing:1;
		unsigned int endEditing:1;
	} _validationEvents;
	
	BOOL _valid;
	BOOL _validated;
	__weak id _componentDelegate;
}

- (instancetype)initWithUIComponent:(UIView *)uiComponent validateOn:(REDValidationEvent)event
{
	self = [super init];
	if (self ) {
		if (event & REDValidationEventAll) {
			_validationEvents.change = 1;
			_validationEvents.beginEditing = 1;
			_validationEvents.endEditing = 1;
		} else {
			_validationEvents.change = event & REDValidationEventChange;
			_validationEvents.beginEditing = event & REDValidationEventBeginEditing;
			_validationEvents.endEditing = event & REDValidationEventEndEditing;
		}
		
		_uiComponent = uiComponent;
		_tag = uiComponent.tag;
		[self setupComponentDelegate];
	}
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setRule:(id<REDValidationRuleProtocol>)rule
{
	_rule = rule;
	if ([_rule isKindOfClass:[REDNetworkValidationRule class]]) {
		((REDNetworkValidationRule *)_rule).delegate = self;
	}
}

- (void)setUiComponent:(UIView *)uiComponent
{
	if (uiComponent) {
		_uiComponent = uiComponent;
		[self setupComponentDelegate];
	} else {
		if ([_uiComponent isKindOfClass:[UITextField class]]) {
			[[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:_uiComponent];
		} else if ([_uiComponent isNonTextControlClass]) {
			[(UIControl *)_uiComponent removeTarget:self action:@selector(componentValueChanged:) forControlEvents:UIControlEventValueChanged];
		}
		_uiComponent = uiComponent;
	}
}

- (BOOL)valid
{
	return _validated ? _valid : _uiComponent ? [self validateUIComponent:_uiComponent withCallbacks:YES] : NO;
}

- (void)setupComponentDelegate
{
	if ([_uiComponent isKindOfClass:[UITextField class]]) {
		UITextField *component = (UITextField *)_uiComponent;
		if (component.delegate != self) {
			_componentDelegate = component.delegate;
			component.delegate = self;
		}
		
		if (_validationEvents.change) {
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:UITextFieldTextDidChangeNotification object:component];
		}
	} else if ([_uiComponent isKindOfClass:[UITextView class]]) {
		UITextView *component = (UITextView *)_uiComponent;
		if (component.delegate != self) {
			_componentDelegate = component.delegate;
			component.delegate = self;
		}
	} else if ([_uiComponent isNonTextControlClass]) {
		UIControl *component = (UIControl *)_uiComponent;
		if (_validationEvents.change) {
			[component addTarget:self action:@selector(componentValueChanged:) forControlEvents:UIControlEventValueChanged];
		}
	}
}

- (BOOL)validateUIComponent:(UIView *)uiComponent withCallbacks:(BOOL)callback
{
	_uiComponent = uiComponent;
	
	if (callback) {
		[_delegate validationComponent:self willValidateUIComponent:uiComponent];
	}
	
	BOOL result = [_rule validate:uiComponent] & REDValidationResultSuccess;
	_valid = result;
	_validated = YES;
	
	if (callback && [_rule isKindOfClass:[REDNetworkValidationRule class]] == NO) {
		[_delegate validationComponent:self didValidateUIComponent:uiComponent result:result];
	}
	
	return result;
}

#pragma mark - Actions

- (void)componentValueChanged:(UIView *)component
{
	[self validateUIComponent:component withCallbacks:YES];
}

#pragma mark - Notifications

- (void)textDidChange:(NSNotification *)notification
{
	[self validateUIComponent:notification.object withCallbacks:YES];
}

#pragma mark - NetworkValidationRuleDelegate

- (void)validationRule:(id<REDValidationRuleProtocol>)rule didValidateWithResult:(REDValidationResult)result error:(NSError *)error
{
	_valid = result & REDValidationResultSuccess;
	_validated = YES;
	[_delegate validationComponent:self didValidateUIComponent:_uiComponent result:result];
}

#pragma mark - Delegate Funny Business

- (BOOL)respondsToSelector:(SEL)aSelector
{
	if ([super respondsToSelector:aSelector]) {
		return YES;
	} else if ([_componentDelegate respondsToSelector:aSelector]) {
		return YES;
	}
	
	return [super respondsToSelector:aSelector];
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
	if ([super respondsToSelector:aSelector]) {
		return self;
	} else if ([_componentDelegate respondsToSelector:aSelector]) {
		return _componentDelegate;
	}
	
	return [super forwardingTargetForSelector:aSelector];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	if (_validationEvents.beginEditing) {
		[self validateUIComponent:textField withCallbacks:YES];
	}
	if ([_componentDelegate respondsToSelector:@selector(textFieldDidBeginEditing:)]) {
		[_componentDelegate textFieldDidBeginEditing:textField];
	}
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	if (_validationEvents.endEditing) {
		[self validateUIComponent:textField withCallbacks:YES];
	}
	if ([_componentDelegate respondsToSelector:@selector(textFieldDidEndEditing:)]) {
		[_componentDelegate textFieldDidEndEditing:textField];
	}
}

#pragma mark - UITextViewDelegate

- (void)textViewDidBeginEditing:(UITextView *)textView
{
	if (_validationEvents.beginEditing) {
		[self validateUIComponent:textView withCallbacks:YES];
	}
	if ([_componentDelegate respondsToSelector:@selector(textViewDidBeginEditing:)]) {
		[_componentDelegate textViewDidBeginEditing:textView];
	}
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
	if (_validationEvents.endEditing) {
		[self validateUIComponent:textView withCallbacks:YES];
	}
	if ([_componentDelegate respondsToSelector:@selector(textViewDidEndEditing:)]) {
		[_componentDelegate textViewDidEndEditing:textView];
	}
}

- (void)textViewDidChange:(UITextView *)textView
{
	if (_validationEvents.change) {
		[self validateUIComponent:textView withCallbacks:YES];
	}
	if ([_componentDelegate respondsToSelector:@selector(textViewDidChange:)]) {
		[_componentDelegate textViewDidChange:textView];
	}
}
@end

@implementation UIView (Control)

- (BOOL)isNonTextControlClass
{
	return [self isKindOfClass:[UIControl class]] && ([self isKindOfClass:[UITextField class]] || [self isKindOfClass:[UITextView class]]);
}

@end
