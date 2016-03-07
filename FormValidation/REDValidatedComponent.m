//
//  REDValidatedComponent.m
//  REDFormValidation
//
//  Created by Sam Dye on 2016-03-04.
//  Copyright © 2016 Sam Dye. All rights reserved.
//

#import "REDValidatedComponent.h"

#import "REDValidationRule.h"

@interface REDValidatedComponent (UITextField) <UITextFieldDelegate>
@end

@interface REDValidatedComponent (UITextView) <UITextViewDelegate>
@end

@interface REDValidatedComponent () <REDNetworkValidationRuleDelegate>
@property (nonatomic, weak) id componentDelegate;
@end

@implementation REDValidatedComponent {
	struct {
		unsigned int change:1;
		unsigned int beginEditing:1;
		unsigned int endEditing:1;
	} _validationEvents;
	
	BOOL _valid;
}

- (instancetype)initWithUIComponent:(UIControl *)uiComponent validateOn:(REDValidationEvent)event
{
	self = [super init];
	if (self ) {
		_uiComponent = uiComponent;
		_tag = uiComponent.tag;
		
		if (event & REDValidationEventAll) {
			_validationEvents.change = 1;
			_validationEvents.beginEditing = 1;
			_validationEvents.endEditing = 1;
		} else {
			_validationEvents.change = event & REDValidationEventChange;
			_validationEvents.beginEditing = event & REDValidationEventBeginEditing;
			_validationEvents.endEditing = event & REDValidationEventEndEditing;
		}
		
		if ([_uiComponent isKindOfClass:[UITextField class]]) {
			_componentDelegate = ((UITextField *)_uiComponent).delegate;
			((UITextField *)uiComponent).delegate = self;
			
			if (_validationEvents.change) {
				[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:UITextFieldTextDidChangeNotification object:_uiComponent];
			}
		} else if ([_uiComponent isKindOfClass:[UITextView class]]) {
			_componentDelegate = ((UITextView *)_uiComponent).delegate;
			((UITextView *)uiComponent).delegate = self;
		} else if ([_uiComponent isKindOfClass:[UIDatePicker class]] || [_uiComponent isKindOfClass:[UISegmentedControl class]] || [_uiComponent isKindOfClass:[UISlider class]] || [_uiComponent isKindOfClass:[UIStepper class]] || [_uiComponent isKindOfClass:[UISwitch class]]) {
			if (_validationEvents.change) {
				[_uiComponent addTarget:self action:@selector(componentValueChanged:) forControlEvents:UIControlEventValueChanged];
			}
		}
		
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

- (BOOL)validateWithCallbacks:(BOOL)callback
{
	if (callback) {
		[_delegate validatedComponent:self willValidateUIComponent:_uiComponent];
	}
	
	BOOL result = [_rule validate:_uiComponent] & REDValidationResultSuccess;
	_valid = result;
	_validated = YES;
	
	if (callback && [_rule isKindOfClass:[REDNetworkValidationRule class]] == NO) {
		[_delegate validatedComponent:self didValidateUIComponent:_uiComponent result:result];
	}
	
	return result;
}

#pragma mark - Actions

- (void)componentValueChanged:(UIControl *)component
{
	[self validateWithCallbacks:YES];
}

#pragma mark - Notifications

- (void)textDidChange:(NSNotification *)notification
{
	[self validateWithCallbacks:YES];
}

#pragma mark - NetworkValidationRuleDelegate

- (void)validationRule:(id<REDValidationRuleProtocol>)rule didValidateWithResult:(REDValidationResult)result error:(NSError *)error
{
	_valid = result & REDValidationResultSuccess;
	_validated = YES;
	[_delegate validatedComponent:self didValidateUIComponent:_uiComponent result:result];
}

@end

#pragma mark - Public Interface

@implementation REDValidatedComponent (Public)

- (BOOL)valid
{
	return _validated ? _valid : [self validateWithCallbacks:YES];
}

- (void)setValid:(BOOL)valid
{
	_valid = valid;
}

@end

#pragma mark - UITextFieldDelegate

@implementation REDValidatedComponent (UITextField)

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
	return _componentDelegate && [_componentDelegate respondsToSelector:@selector(textFieldShouldBeginEditing:)] ? [_componentDelegate textFieldShouldBeginEditing:textField] : YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	if (_validationEvents.beginEditing) {
		[self validateWithCallbacks:YES];
	}
	if ([_componentDelegate respondsToSelector:@selector(textFieldDidBeginEditing:)]) {
		[_componentDelegate textFieldDidBeginEditing:textField];
	}
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
	return _componentDelegate && [_componentDelegate respondsToSelector:@selector(textFieldShouldEndEditing:)] ? [_componentDelegate textFieldShouldEndEditing:textField] : YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	if (_validationEvents.endEditing) {
		[self validateWithCallbacks:YES];
	}
	if ([_componentDelegate respondsToSelector:@selector(textFieldDidEndEditing:)]) {
		[_componentDelegate textFieldDidEndEditing:textField];
	}
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	return _componentDelegate && [_componentDelegate respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)] ? [_componentDelegate textField:textField shouldChangeCharactersInRange:range replacementString:string] : YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
	return _componentDelegate && [_componentDelegate respondsToSelector:@selector(textFieldShouldClear:)] ? [_componentDelegate textFieldShouldClear:textField] : YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	return _componentDelegate && [_componentDelegate respondsToSelector:@selector(textFieldShouldReturn:)] ? [_componentDelegate textFieldShouldReturn:textField] : YES;
}

@end

#pragma mark - UITextViewDelegate

@implementation REDValidatedComponent (UITextView)

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
	return _componentDelegate && [_componentDelegate respondsToSelector:@selector(textViewShouldBeginEditing:)] ? [_componentDelegate textViewShouldBeginEditing:textView] : YES;
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView
{
	return _componentDelegate && [_componentDelegate respondsToSelector:@selector(textViewShouldEndEditing:)] ? [_componentDelegate textViewShouldEndEditing:textView] : YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
	if (_validationEvents.beginEditing) {
		[self validateWithCallbacks:YES];
	}
	if ([_componentDelegate respondsToSelector:@selector(textViewDidBeginEditing:)]) {
		[_componentDelegate textViewDidBeginEditing:textView];
	}
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
	if (_validationEvents.endEditing) {
		[self validateWithCallbacks:YES];
	}
	if ([_componentDelegate respondsToSelector:@selector(textViewDidEndEditing:)]) {
		[_componentDelegate textViewDidEndEditing:textView];
	}
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
	return _componentDelegate && [_componentDelegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)] ? [_componentDelegate textView:textView shouldChangeTextInRange:range replacementText:text] : YES;
}

- (void)textViewDidChange:(UITextView *)textView
{
	if (_validationEvents.change) {
		[self validateWithCallbacks:YES];
	}
	if ([_componentDelegate respondsToSelector:@selector(textViewDidChange:)]) {
		[_componentDelegate textViewDidChange:textView];
	}
}

- (void)textViewDidChangeSelection:(UITextView *)textView
{
	if ([_componentDelegate respondsToSelector:@selector(textViewDidChangeSelection:)]) {
		[_componentDelegate textViewDidChangeSelection:textView];
	}
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange
{
	return _componentDelegate && [_componentDelegate respondsToSelector:@selector(textView:shouldInteractWithURL:inRange:)] ? [_componentDelegate textView:textView shouldInteractWithURL:URL inRange:characterRange] : YES;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithTextAttachment:(NSTextAttachment *)textAttachment inRange:(NSRange)characterRange
{
	return _componentDelegate && [_componentDelegate respondsToSelector:@selector(textView:shouldInteractWithTextAttachment:inRange:)] ? [_componentDelegate textView:textView shouldInteractWithTextAttachment:textAttachment inRange:characterRange] : YES;
}

@end
