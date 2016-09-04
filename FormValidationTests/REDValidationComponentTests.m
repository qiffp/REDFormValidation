//
//  REDValidationComponentTests.m
//  REDFormValidation
//
//  Created by Sam Dye on 2016-03-12.
//  Copyright © 2016 Sam Dye. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import "REDValidationComponent.h"

@interface REDValidationComponent (TestHelper)
@property (nonatomic, assign, readwrite) REDValidationResult valid;
@end

@implementation REDValidationComponent (TestHelper)

- (void)setValid:(REDValidationResult)valid
{
	[self setValue:@(valid) forKey:@"_valid"];
}

@end

@interface REDValidationComponentTests : XCTestCase
@end

@implementation REDValidationComponentTests {
	UITextField *_textField;
	REDValidationComponent *_component;
	id _delegate;
}

- (void)setUp
{
    [super setUp];
	
	_delegate = [OCMockObject niceMockForProtocol:@protocol(REDValidationComponentDelegate)];
	_textField = [UITextField new];
	_textField.text = @"test";
	
	_component = [[REDValidationComponent alloc] initWithInitialValue:nil validationEvent:REDValidationEventAll rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}]];
	_component.uiComponent = _textField;
	_component.delegate = _delegate;
}

- (void)tearDown
{
	[_delegate verify];
	
	_textField = nil;
	_component = nil;
	_delegate = nil;
	
    [super tearDown];
}

#pragma mark - valid

- (void)testNewComponentIsUnvalidated
{
	XCTAssertEqual(_component.valid, REDValidationResultUnvalidated);
}

#pragma mark - validate

- (void)testValidateReturnsValidResultIfShouldValidateIsFalse
{
	_component.shouldValidate = NO;
	_component.valid = REDValidationResultUnvalidated;
	XCTAssertEqual([_component validate], REDValidationResultValid);
}

- (void)testValidateValidatesUIComponentIfThereIsOne
{
	XCTAssertNotNil(_component.uiComponent);
	XCTAssertTrue(_component.shouldValidate);
	XCTAssertEqual([_component validate], REDValidationResultValid);
}

- (void)testValidateReturnsExistingValidValueIfComponentHasNoUIComponentAndHasNoInitialValue
{
	_component.uiComponent = nil;
	
	_component.valid = REDValidationResultValid;
	XCTAssertEqual([_component validate], REDValidationResultValid);
	
	_component.valid = REDValidationResultInvalid;
	XCTAssertEqual([_component validate], REDValidationResultInvalid);
}

- (void)testValidateValidatesInitialValueIfComponentHasNoUIComponentAndIsUnvalidated
{
	_component = [[REDValidationComponent alloc] initWithInitialValue:@"hi" validationEvent:REDValidationEventAll rule:[REDValidationRule ruleWithBlock:^BOOL(NSString *value) {
		return value.length > 4;
	}]];
	_component.valid = REDValidationResultUnvalidated;
	XCTAssertEqual([_component validate], REDValidationResultInvalid);
	
	_component = [[REDValidationComponent alloc] initWithInitialValue:@"hello" validationEvent:REDValidationEventAll rule:[REDValidationRule ruleWithBlock:^BOOL(NSString *value) {
		return value.length > 4;
	}]];
	_component.valid = REDValidationResultUnvalidated;
	XCTAssertEqual([_component validate], REDValidationResultValid);
}

- (void)testValidateDoesNotValidateInitialValueIfComponentHasNoUIComponentAndIsValidated
{
	_component = [[REDValidationComponent alloc] initWithInitialValue:@"hi" validationEvent:REDValidationEventAll rule:[REDValidationRule ruleWithBlock:^BOOL(NSString *value) {
		return value.length > 4;
	}]];
	_component.valid = REDValidationResultValid;
	XCTAssertEqual([_component validate], REDValidationResultValid);
}

#pragma mark - validationEvent

- (void)testTextFieldValidatesOnBeginEditingWithValidationEventBeginEditing
{
	_component = [[REDValidationComponent alloc] initWithInitialValue:nil validationEvent:REDValidationEventBeginEditing rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}]];
	_component.uiComponent = _textField;
	_component.delegate = _delegate;
	
	__block NSUInteger callCount = 0;
	[[[_delegate stub] andDo:^(NSInvocation *invocation) {
		callCount++;
	}] validationComponent:[OCMArg any] didValidateUIComponent:[OCMArg any] result:REDValidationResultValid error:[OCMArg any]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidBeginEditingNotification object:_component.uiComponent];
	XCTAssertEqual(callCount, 1, @"callCount should increment after begin editing");
	
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidEndEditingNotification object:_component.uiComponent];
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification object:_component.uiComponent];
	XCTAssertEqual(callCount, 1, @"callCount should not increase after other notifications");
}

- (void)testTextFieldValidatesOnEndEditingWithValidationEventEndEditing
{
	_component = [[REDValidationComponent alloc] initWithInitialValue:nil validationEvent:REDValidationEventEndEditing rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}]];
	_component.uiComponent = _textField;
	_component.delegate = _delegate;
	
	__block NSUInteger callCount = 0;
	[[[_delegate stub] andDo:^(NSInvocation *invocation) {
		callCount++;
	}] validationComponent:[OCMArg any] didValidateUIComponent:[OCMArg any] result:REDValidationResultValid error:[OCMArg any]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidEndEditingNotification object:_component.uiComponent];
	XCTAssertEqual(callCount, 1, @"callCount should increment after end editing notification");
	
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidBeginEditingNotification object:_component.uiComponent];
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification object:_component.uiComponent];
	XCTAssertEqual(callCount, 1, @"callCount should not increase after other notifications");
}

- (void)testTextFieldValidatesOnChangeWithValidationEventChange
{
	_component = [[REDValidationComponent alloc] initWithInitialValue:nil validationEvent:REDValidationEventChange rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}]];
	_component.uiComponent = _textField;
	_component.delegate = _delegate;
	
	__block NSUInteger callCount = 0;
	[[[_delegate stub] andDo:^(NSInvocation *invocation) {
		callCount++;
	}] validationComponent:[OCMArg any] didValidateUIComponent:[OCMArg any] result:REDValidationResultValid error:[OCMArg any]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification object:_component.uiComponent];
	XCTAssertEqual(callCount, 1, @"callCount should increment after change notification");
	
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidBeginEditingNotification object:_component.uiComponent];
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidEndEditingNotification object:_component.uiComponent];
	XCTAssertEqual(callCount, 1, @"callCount should not increase after other notifications");
}

- (void)testTextFieldValidatesOnAllEventsWithValidationEventAll
{
	__block NSUInteger callCount = 0;
	[[[_delegate stub] andDo:^(NSInvocation *invocation) {
		callCount++;
	}] validationComponent:[OCMArg any] didValidateUIComponent:[OCMArg any] result:REDValidationResultValid error:[OCMArg any]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidBeginEditingNotification object:_component.uiComponent];
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidEndEditingNotification object:_component.uiComponent];
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification object:_component.uiComponent];
	
	XCTAssertEqual(callCount, 3, @"callCount should have been incremented for each event");
}

- (void)testTextViewValidatesOnBeginEditingWithValidationEventBeginEditing
{
	UITextView *textView = [UITextView new];
	textView.text = @"test";
	_component = [[REDValidationComponent alloc] initWithInitialValue:nil validationEvent:REDValidationEventBeginEditing rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}]];
	_component.uiComponent = textView;
	_component.delegate = _delegate;
	
	__block NSUInteger callCount = 0;
	[[[_delegate stub] andDo:^(NSInvocation *invocation) {
		callCount++;
	}] validationComponent:[OCMArg any] didValidateUIComponent:[OCMArg any] result:REDValidationResultValid error:[OCMArg any]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidBeginEditingNotification object:_component.uiComponent];
	XCTAssertEqual(callCount, 1, @"callCount should increment after begin editing");
	
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidEndEditingNotification object:_component.uiComponent];
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidChangeNotification object:_component.uiComponent];
	XCTAssertEqual(callCount, 1, @"callCount should not increase after other notifications");
}

- (void)testTextViewValidatesOnEndEditingWithValidationEventEndEditing
{
	UITextView *textView = [UITextView new];
	textView.text = @"test";
	_component = [[REDValidationComponent alloc] initWithInitialValue:nil validationEvent:REDValidationEventEndEditing rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}]];
	_component.uiComponent = textView;
	_component.delegate = _delegate;
	
	__block NSUInteger callCount = 0;
	[[[_delegate stub] andDo:^(NSInvocation *invocation) {
		callCount++;
	}] validationComponent:[OCMArg any] didValidateUIComponent:[OCMArg any] result:REDValidationResultValid error:[OCMArg any]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidEndEditingNotification object:_component.uiComponent];
	XCTAssertEqual(callCount, 1, @"callCount should increment after end editing notification");
	
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidBeginEditingNotification object:_component.uiComponent];
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidChangeNotification object:_component.uiComponent];
	XCTAssertEqual(callCount, 1, @"callCount should not increase after other notifications");
}

- (void)testTextViewValidatesOnChangeWithValidationEventChange
{
	UITextView *textView = [UITextView new];
	textView.text = @"test";
	_component = [[REDValidationComponent alloc] initWithInitialValue:nil validationEvent:REDValidationEventChange rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}]];
	_component.uiComponent = textView;
	_component.delegate = _delegate;
	
	__block NSUInteger callCount = 0;
	[[[_delegate stub] andDo:^(NSInvocation *invocation) {
		callCount++;
	}] validationComponent:[OCMArg any] didValidateUIComponent:[OCMArg any] result:REDValidationResultValid error:[OCMArg any]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidChangeNotification object:_component.uiComponent];
	XCTAssertEqual(callCount, 1, @"callCount should increment after change notification");
	
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidBeginEditingNotification object:_component.uiComponent];
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidEndEditingNotification object:_component.uiComponent];
	XCTAssertEqual(callCount, 1, @"callCount should not increase after other notifications");
}

- (void)testTextViewValidatesOnAllEventsWithValidationEventAll
{
	UITextView *textView = [UITextView new];
	textView.text = @"test";
	_component.uiComponent = textView;
	
	__block NSUInteger callCount = 0;
	[[[_delegate stub] andDo:^(NSInvocation *invocation) {
		callCount++;
	}] validationComponent:[OCMArg any] didValidateUIComponent:[OCMArg any] result:REDValidationResultValid error:[OCMArg any]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidBeginEditingNotification object:_component.uiComponent];
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidEndEditingNotification object:_component.uiComponent];
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidChangeNotification object:_component.uiComponent];
	
	XCTAssertEqual(callCount, 3, @"callCount should have been incremented for each event");
}

- (void)testControlValidatesOnBeginEditingWithValidationEventBeginEditing
{
	UISlider *slider = [UISlider new];
	_component = [[REDValidationComponent alloc] initWithInitialValue:nil validationEvent:REDValidationEventBeginEditing rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}]];
	_component.uiComponent = slider;
	
	// sendActionsForControlEvents: doesn't work while unit testing, so verify target/events instead
	NSSet *targets = slider.allTargets;
	XCTAssertEqual(targets.count, 1);
	
	id target = targets.allObjects.firstObject;
	XCTAssertEqualObjects(target, _component);
	XCTAssertEqual([slider actionsForTarget:target forControlEvent:UIControlEventEditingDidBegin].count, 1);
	XCTAssertEqual([slider actionsForTarget:target forControlEvent:UIControlEventEditingDidEnd].count, 0);
	XCTAssertEqual([slider actionsForTarget:target forControlEvent:UIControlEventValueChanged].count, 0);
}

- (void)testControlValidatesOnEndEditingWithValidationEventEndEditing
{
	UISlider *slider = [UISlider new];
	_component = [[REDValidationComponent alloc] initWithInitialValue:nil validationEvent:REDValidationEventEndEditing rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}]];
	_component.uiComponent = slider;
	
	// sendActionsForControlEvents: doesn't work while unit testing, so verify target/events instead
	NSSet *targets = slider.allTargets;
	XCTAssertEqual(targets.count, 1);
	
	id target = targets.allObjects.firstObject;
	XCTAssertEqualObjects(target, _component);
	XCTAssertEqual([slider actionsForTarget:target forControlEvent:UIControlEventEditingDidBegin].count, 0);
	XCTAssertEqual([slider actionsForTarget:target forControlEvent:UIControlEventEditingDidEnd].count, 1);
	XCTAssertEqual([slider actionsForTarget:target forControlEvent:UIControlEventValueChanged].count, 0);
}

- (void)testControlValidatesOnChangeWithValidationEventChange
{
	UISlider *slider = [UISlider new];
	_component = [[REDValidationComponent alloc] initWithInitialValue:nil validationEvent:REDValidationEventChange rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}]];
	_component.uiComponent = slider;
	
	// sendActionsForControlEvents: doesn't work while unit testing, so verify target/events instead
	NSSet *targets = slider.allTargets;
	XCTAssertEqual(targets.count, 1);
	
	id target = targets.allObjects.firstObject;
	XCTAssertEqualObjects(target, _component);
	XCTAssertEqual([slider actionsForTarget:target forControlEvent:UIControlEventEditingDidBegin].count, 0);
	XCTAssertEqual([slider actionsForTarget:target forControlEvent:UIControlEventEditingDidEnd].count, 0);
	XCTAssertEqual([slider actionsForTarget:target forControlEvent:UIControlEventValueChanged].count, 1);
}

- (void)testControlValidatesOnAllEventsWithValidationEventAll
{
	UISlider *slider = [UISlider new];
	_component.uiComponent = slider;
	
	// sendActionsForControlEvents: doesn't work while unit testing, so verify target/events instead
	NSSet *targets = slider.allTargets;
	XCTAssertEqual(targets.count, 1);
	
	id target = targets.allObjects.firstObject;
	XCTAssertEqualObjects(target, _component);
	XCTAssertEqual([slider actionsForTarget:target forControlEvent:UIControlEventEditingDidBegin].count, 1);
	XCTAssertEqual([slider actionsForTarget:target forControlEvent:UIControlEventEditingDidEnd].count, 1);
	XCTAssertEqual([slider actionsForTarget:target forControlEvent:UIControlEventValueChanged].count, 1);
}

#pragma mark - evaluateDefaultValidity

- (void)testEvaluateDefaultValidityReturnsDefaultValidIfAllowsDefaultAndComponentValueIsDefaultValue
{
	REDValidationRule *rule = [REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}];
	rule.allowDefault = YES;
	
	UITextField *textField = [UITextField new];
	
	REDValidationComponent *component = [[REDValidationComponent alloc] initWithInitialValue:nil validationEvent:REDValidationEventAll rule:rule];
	component.uiComponent = textField;
	
	XCTAssertTrue(rule.allowDefault);
	XCTAssertEqualObjects([component.uiComponent validatedValue], kUITextFieldDefaultValue);
	
	XCTAssertEqual([component evaluateDefaultValidity], REDValidationResultDefaultValid);
}

- (void)testEvaluateDefaultValidityReturnsDefaulValidIfAndAllowsDefaultValidAndUIComponentIsNil
{
	REDValidationRule *rule = [REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}];
	rule.allowDefault = YES;
	
	REDValidationComponent *component = [[REDValidationComponent alloc] initWithInitialValue:nil validationEvent:REDValidationEventAll rule:rule];
	
	XCTAssertTrue(rule.allowDefault);
	XCTAssertNil(component.uiComponent);
	
	XCTAssertEqual([component evaluateDefaultValidity], REDValidationResultDefaultValid);
}

- (void)testEvaluateDefaultValidityReturnsExistingValidValueIfRuleDoesNotAllowDefault
{
	REDValidationRule *rule = [REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}];
	
	UITextField *textField = [UITextField new];
	
	REDValidationComponent *component = [[REDValidationComponent alloc] initWithInitialValue:nil validationEvent:REDValidationEventAll rule:rule];
	component.uiComponent = textField;
	
	XCTAssertFalse(rule.allowDefault);
	XCTAssertEqualObjects([component.uiComponent validatedValue], kUITextFieldDefaultValue);
	
	XCTAssertEqual([component evaluateDefaultValidity], component.valid);
}

- (void)testEvaluateDefaultValidityReturnsExistingValidValueIfComponentValueIsNotDefaultValue
{
	REDValidationRule *rule = [REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}];
	rule.allowDefault = YES;
	
	UITextField *textField = [UITextField new];
	textField.text = @"test";
	
	REDValidationComponent *component = [[REDValidationComponent alloc] initWithInitialValue:nil validationEvent:REDValidationEventAll rule:rule];
	component.uiComponent = textField;
	
	XCTAssertTrue(rule.allowDefault);
	XCTAssertNotEqualObjects([component.uiComponent validatedValue], kUITextFieldDefaultValue);
	
	XCTAssertEqual([component evaluateDefaultValidity], component.valid);
}

@end
