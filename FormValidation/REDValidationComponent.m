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
@property (nonatomic, weak) id componentDelegate;
@end

@implementation REDValidationComponent {
	id<REDValidationRule> _rule;
	struct {
		BOOL change;
		BOOL beginEditing;
		BOOL endEditing;
	} _validationEvents;
	
	BOOL _valid;
	BOOL _validated;
}

- (instancetype)init
{
	return [self initWithValidationEvent:REDValidationEventAll rule:nil];
}

- (instancetype)initWithValidationEvent:(REDValidationEvent)event rule:(id<REDValidationRule>)rule
{
	self = [super init];
	if (self ) {
		_shouldValidate = YES;
		
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

- (void)setUiComponent:(UIView *)uiComponent
{
	if (_uiComponent == uiComponent) {
		return;
	}
	
	[self removeComponentEventActions];
	_componentDelegate = nil;
	_uiComponent = uiComponent;
	[self setupComponentEventActions];
}

- (BOOL)valid
{
	if (_shouldValidate) {
		if (_validated) {
			return _valid;
		} else {
			if (_uiComponent) {
				return [self validate];
			} else {
				return NO;
			}
		}
	}
	
	return YES;
}

- (void)removeComponentEventActions
{
	if ([_uiComponent isKindOfClass:[UITextField class]] || [_uiComponent isKindOfClass:[UITextView class]]) {
		[_uiComponent performSelector:@selector(setDelegate:) withObject:_componentDelegate];
	}
	
	if ([_uiComponent isKindOfClass:[UITextField class]]) {
		if (_validationEvents.change) {
			[[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:_uiComponent];
		}
	} else if ([_uiComponent isNonTextControlClass]) {
		UIControl *control = (UIControl *)_uiComponent;
		if (_validationEvents.change) {
			[control removeTarget:self action:@selector(componentValueChanged:) forControlEvents:UIControlEventValueChanged];
		}
		if (_validationEvents.beginEditing) {
			[control removeTarget:self action:@selector(componentDidBeginEditing:) forControlEvents:UIControlEventEditingDidBegin];
		}
		if (_validationEvents.endEditing) {
			[control removeTarget:self action:@selector(componentDidEndEditing:) forControlEvents:UIControlEventEditingDidEnd];
		}
	}
}

- (void)setupComponentEventActions
{
	if ([_uiComponent isKindOfClass:[UITextField class]] || [_uiComponent isKindOfClass:[UITextView class]]) {
		id delegate = [_uiComponent performSelector:@selector(delegate)];
		if (delegate != self) {
			id componentDelegate = nil;
			if ([delegate isKindOfClass:[REDValidationComponent class]]) {
				componentDelegate = ((REDValidationComponent *)delegate).componentDelegate;
			}
			
			_componentDelegate = componentDelegate ?: delegate;
			[_uiComponent performSelector:@selector(setDelegate:) withObject:self];
		}
	}
	
	if ([_uiComponent isKindOfClass:[UITextField class]]) {
		if (_validationEvents.change) {
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:UITextFieldTextDidChangeNotification object:_uiComponent];
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

- (BOOL)validate
{
	if (_shouldValidate) {
		[_delegate validationComponent:self willValidateUIComponent:_uiComponent];
		
		REDValidationResult result = [_rule validate:_uiComponent];
		_validated = result != REDValidationResultPending;
		_valid = result & REDValidationResultSuccess;
		
		if ([_rule isKindOfClass:[REDNetworkValidationRule class]] == NO) {
			[_delegate validationComponent:self didValidateUIComponent:_uiComponent result:_valid];
		}
	}
	
	return _valid;
}

- (void)reset
{
	_valid = NO;
	_validated = NO;
}

#pragma mark - Actions

- (void)componentValueChanged:(UIView *)component
{
	[self validate];
}

- (void)componentDidBeginEditing:(UIView *)component
{
	[self validate];
}

- (void)componentDidEndEditing:(UIView *)component
{
	[self validate];
}

#pragma mark - Notifications

- (void)textDidChange:(NSNotification *)notification
{
	[self validate];
}

#pragma mark - NetworkValidationRuleDelegate

- (void)validationRule:(id<REDValidationRule>)rule completedNetworkValidationOfComponent:(UIView *)component withResult:(REDValidationResult)result error:(NSError *)error
{
	_valid = result & REDValidationResultSuccess;
	_validated = YES;
	[_delegate validationComponent:self didValidateUIComponent:component result:result];
}

#pragma mark - Delegate Funny Business

- (BOOL)respondsToSelector:(SEL)aSelector
{
	return [super respondsToSelector:aSelector] || [_componentDelegate respondsToSelector:aSelector];
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
	if ([_componentDelegate respondsToSelector:aSelector]) {
		return _componentDelegate;
	}
	
	return [super forwardingTargetForSelector:aSelector];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	if (_validationEvents.beginEditing) {
		[self validate];
	}
	if ([_componentDelegate respondsToSelector:@selector(textFieldDidBeginEditing:)]) {
		[_componentDelegate textFieldDidBeginEditing:textField];
	}
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	if (_validationEvents.endEditing) {
		[self validate];
	}
	if ([_componentDelegate respondsToSelector:@selector(textFieldDidEndEditing:)]) {
		[_componentDelegate textFieldDidEndEditing:textField];
	}
}

#pragma mark - UITextViewDelegate

- (void)textViewDidBeginEditing:(UITextView *)textView
{
	if (_validationEvents.beginEditing) {
		[self validate];
	}
	if ([_componentDelegate respondsToSelector:@selector(textViewDidBeginEditing:)]) {
		[_componentDelegate textViewDidBeginEditing:textView];
	}
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
	if (_validationEvents.endEditing) {
		[self validate];
	}
	if ([_componentDelegate respondsToSelector:@selector(textViewDidEndEditing:)]) {
		[_componentDelegate textViewDidEndEditing:textView];
	}
}

- (void)textViewDidChange:(UITextView *)textView
{
	if (_validationEvents.change) {
		[self validate];
	}
	if ([_componentDelegate respondsToSelector:@selector(textViewDidChange:)]) {
		[_componentDelegate textViewDidChange:textView];
	}
}
@end

@implementation UIView (Control)

- (BOOL)isNonTextControlClass
{
	return [self isKindOfClass:[UIControl class]] && !([self isKindOfClass:[UITextField class]] || [self isKindOfClass:[UITextView class]]);
}

@end
