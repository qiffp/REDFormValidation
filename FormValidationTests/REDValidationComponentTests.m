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
	XCTAssertEqual(_component.valid, REDValidationResultUnvalidated, @"Component should be unvalidated");
}

#pragma mark - validate

- (void)testValidateReturnsValidResultIfShouldValidateIsFalse
{
	_component.shouldValidate = NO;
	_component.valid = REDValidationResultUnvalidated;
	XCTAssertEqual([_component validate], REDValidationResultValid, @"Validate should return valid if shouldValidate is false");
}

- (void)testValidateValidatesUIComponentIfThereIsOne
{
	XCTAssertNotNil(_component.uiComponent, @"Should have a uiComponent");
	XCTAssertTrue(_component.shouldValidate, @"Should validate");
	XCTAssertEqual([_component validate], REDValidationResultValid, @"Validation should succeed");
}

- (void)testValidateReturnsExistingValidValueIfComponentHasNoUIComponentAndHasNoInitialValue
{
	_component.uiComponent = nil;
	
	_component.valid = REDValidationResultValid;
	XCTAssertEqual([_component validate], REDValidationResultValid, @"Validate should return previous `valid` value if there is no uiComponent");
	
	_component.valid = REDValidationResultInvalid;
	XCTAssertEqual([_component validate], REDValidationResultInvalid, @"Validate should return previous `valid` value if there is no uiCompnent");
}

- (void)testValidateValidatesInitialValueIfComponentHasNoUIComponentAndIsUnvalidated
{
	_component = [[REDValidationComponent alloc] initWithInitialValue:@"hi" validationEvent:REDValidationEventAll rule:[REDValidationRule ruleWithBlock:^BOOL(NSString *value) {
		return value.length > 4;
	}]];
	_component.valid = REDValidationResultUnvalidated;
	XCTAssertEqual([_component validate], REDValidationResultInvalid, @"Validation should fail");
	
	_component = [[REDValidationComponent alloc] initWithInitialValue:@"hello" validationEvent:REDValidationEventAll rule:[REDValidationRule ruleWithBlock:^BOOL(NSString *value) {
		return value.length > 4;
	}]];
	_component.valid = REDValidationResultUnvalidated;
	XCTAssertEqual([_component validate], REDValidationResultValid, @"Validation should succeed");
}

- (void)testValidateDoesNotValidateInitialValueIfComponentHasNoUIComponentAndIsValidated
{
	_component = [[REDValidationComponent alloc] initWithInitialValue:@"hi" validationEvent:REDValidationEventAll rule:[REDValidationRule ruleWithBlock:^BOOL(NSString *value) {
		return value.length > 4;
	}]];
	_component.valid = REDValidationResultValid;
	XCTAssertEqual([_component validate], REDValidationResultValid, @"Validation should return previous `valid` value if it has already been validated");
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
	XCTAssertEqual(targets.count, 1, @"There should be a single target");
	
	id target = targets.allObjects.firstObject;
	XCTAssertEqualObjects(target, _component, @"_component should be the single target");
	XCTAssertEqual([slider actionsForTarget:target forControlEvent:UIControlEventEditingDidBegin].count, 1, @"Target should have 1 action for EditingDidBegin");
	XCTAssertEqual([slider actionsForTarget:target forControlEvent:UIControlEventEditingDidEnd].count, 0, @"Target should have 0 actions for EditingDidEnd");
	XCTAssertEqual([slider actionsForTarget:target forControlEvent:UIControlEventValueChanged].count, 0, @"Target should have 0 actions for ValueChanged");
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
	XCTAssertEqual(targets.count, 1, @"There should be a single target");
	
	id target = targets.allObjects.firstObject;
	XCTAssertEqualObjects(target, _component, @"_component should be the single target");
	XCTAssertEqual([slider actionsForTarget:target forControlEvent:UIControlEventEditingDidBegin].count, 0, @"Target should have 0 actions for EditingDidBegin");
	XCTAssertEqual([slider actionsForTarget:target forControlEvent:UIControlEventEditingDidEnd].count, 1, @"Target should have 1 action for EditingDidEnd");
	XCTAssertEqual([slider actionsForTarget:target forControlEvent:UIControlEventValueChanged].count, 0, @"Target should have 0 actions for ValueChanged");
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
	XCTAssertEqual(targets.count, 1, @"There should be a single target");
	
	id target = targets.allObjects.firstObject;
	XCTAssertEqualObjects(target, _component, @"_component should be the single target");
	XCTAssertEqual([slider actionsForTarget:target forControlEvent:UIControlEventEditingDidBegin].count, 0, @"Target should have 0 actions for EditingDidBegin");
	XCTAssertEqual([slider actionsForTarget:target forControlEvent:UIControlEventEditingDidEnd].count, 0, @"Target should have 0 actions for EditingDidEnd");
	XCTAssertEqual([slider actionsForTarget:target forControlEvent:UIControlEventValueChanged].count, 1, @"Target should have 1 action for ValueChanged");
}

- (void)testControlValidatesOnAllEventsWithValidationEventAll
{
	UISlider *slider = [UISlider new];
	_component.uiComponent = slider;
	
	// sendActionsForControlEvents: doesn't work while unit testing, so verify target/events instead
	NSSet *targets = slider.allTargets;
	XCTAssertEqual(targets.count, 1, @"There should be a single target");
	
	id target = targets.allObjects.firstObject;
	XCTAssertEqualObjects(target, _component, @"_component should be the single target");
	XCTAssertEqual([slider actionsForTarget:target forControlEvent:UIControlEventEditingDidBegin].count, 1, @"Target should have 1 action for EditingDidBegin");
	XCTAssertEqual([slider actionsForTarget:target forControlEvent:UIControlEventEditingDidEnd].count, 1, @"Target should have 1 action for EditingDidEnd");
	XCTAssertEqual([slider actionsForTarget:target forControlEvent:UIControlEventValueChanged].count, 1, @"Target should have 1 action for ValueChanged");
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
	
	XCTAssertTrue(rule.allowDefault, @"Rule should allow default value");
	XCTAssertEqualObjects([component.uiComponent validatedValue], kUITextFieldDefaultValue, @"Validated value should be default value");
	
	XCTAssertEqual([component evaluateDefaultValidity], REDValidationResultDefaultValid, @"Should be default valid");
}

- (void)testEvaluateDefaultValidityReturnsDefaulValidIfAndAllowsDefaultValidAndUIComponentIsNil
{
	REDValidationRule *rule = [REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}];
	rule.allowDefault = YES;
	
	REDValidationComponent *component = [[REDValidationComponent alloc] initWithInitialValue:nil validationEvent:REDValidationEventAll rule:rule];
	
	XCTAssertTrue(rule.allowDefault, @"Rule should allow default value");
	XCTAssertNil(component.uiComponent, @"UIComponent should be nil");
	
	XCTAssertEqual([component evaluateDefaultValidity], REDValidationResultDefaultValid, @"Should be default valid");
}

- (void)testEvaluateDefaultValidityReturnsExistingValidValueIfRuleDoesNotAllowDefault
{
	REDValidationRule *rule = [REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}];
	
	UITextField *textField = [UITextField new];
	
	REDValidationComponent *component = [[REDValidationComponent alloc] initWithInitialValue:nil validationEvent:REDValidationEventAll rule:rule];
	component.uiComponent = textField;
	
	XCTAssertFalse(rule.allowDefault, @"Rule should not allow default value");
	XCTAssertEqualObjects([component.uiComponent validatedValue], kUITextFieldDefaultValue, @"Validated value should be default value");
	
	XCTAssertEqual([component evaluateDefaultValidity], component.valid, @"Should be equal to existing `valid` value");
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
	
	XCTAssertTrue(rule.allowDefault, @"Rule should allow default value");
	XCTAssertNotEqualObjects([component.uiComponent validatedValue], kUITextFieldDefaultValue, @"Validated value should not be default value");
	
	XCTAssertEqual([component evaluateDefaultValidity], component.valid, @"Should be equal to existing `valid` value");
}

@end
