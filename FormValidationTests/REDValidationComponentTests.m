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

@interface REDValidationComponent (TestExpose)
- (void)textDidChange:(NSNotification *)notification;
- (void)textDidEndEditing:(NSNotification *)notification;
@end

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
}

- (void)setUp
{
    [super setUp];
	
	_textField = [UITextField new];
	_textField.text = @"test";
	
	_component = [[REDValidationComponent alloc] initWithIdentifier:nil rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}]];
	_component.uiComponent = _textField;
}

- (void)tearDown
{
	_textField = nil;
	_component = nil;
	
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
	_component = [[REDValidationComponent alloc] initWithIdentifier:nil initialValue:@"hi" validationEvent:REDValidationEventDefault rule:[REDValidationRule ruleWithBlock:^BOOL(NSString *value) {
		return value.length > 4;
	}]];
	_component.valid = REDValidationResultUnvalidated;
	XCTAssertEqual([_component validate], REDValidationResultInvalid);
	
	_component = [[REDValidationComponent alloc] initWithIdentifier:nil initialValue:@"hello" validationEvent:REDValidationEventDefault rule:[REDValidationRule ruleWithBlock:^BOOL(NSString *value) {
		return value.length > 4;
	}]];
	_component.valid = REDValidationResultUnvalidated;
	XCTAssertEqual([_component validate], REDValidationResultValid);
}

- (void)testValidateDoesNotValidateInitialValueIfComponentHasNoUIComponentAndIsValidated
{
	_component = [[REDValidationComponent alloc] initWithIdentifier:nil initialValue:@"hi" validationEvent:REDValidationEventDefault rule:[REDValidationRule ruleWithBlock:^BOOL(NSString *value) {
		return value.length > 4;
	}]];
	_component.valid = REDValidationResultValid;
	XCTAssertEqual([_component validate], REDValidationResultValid);
}

#pragma mark - validationEvent

- (void)testTextFieldValidatesOnEndEditingWithValidationEventEndEditing
{
	_component = [[REDValidationComponent alloc] initWithIdentifier:nil initialValue:nil validationEvent:REDValidationEventEndEditing rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}]];
	_component.uiComponent = _textField;
	
	id componentMock = [OCMockObject partialMockForObject:_component];
	[[componentMock reject] textDidChange:[OCMArg any]];
	[[componentMock expect] textDidEndEditing:[OCMArg any]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidEndEditingNotification object:_component.uiComponent];
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification object:_component.uiComponent];
	
	[componentMock verify];
}

- (void)testTextFieldValidatesOnAllEventsWithValidationEventDefault
{
	id componentMock = [OCMockObject partialMockForObject:_component];
	[[componentMock expect] textDidChange:[OCMArg any]];
	[[componentMock expect] textDidEndEditing:[OCMArg any]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidEndEditingNotification object:_component.uiComponent];
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification object:_component.uiComponent];
	
	[componentMock verify];
}

- (void)testTextViewValidatesOnEndEditingWithValidationEventEndEditing
{
	UITextView *textView = [UITextView new];
	textView.text = @"test";
	_component = [[REDValidationComponent alloc] initWithIdentifier:nil initialValue:nil validationEvent:REDValidationEventEndEditing rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}]];
	_component.uiComponent = textView;
	
	id componentMock = [OCMockObject partialMockForObject:_component];
	[[componentMock reject] textDidChange:[OCMArg any]];
	[[componentMock expect] textDidEndEditing:[OCMArg any]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidEndEditingNotification object:_component.uiComponent];
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidChangeNotification object:_component.uiComponent];
	
	[componentMock verify];
}

- (void)testTextViewValidatesOnAllEventsWithValidationEventDefault
{
	UITextView *textView = [UITextView new];
	textView.text = @"test";
	_component.uiComponent = textView;
	
	id componentMock = [OCMockObject partialMockForObject:_component];
	[[componentMock expect] textDidChange:[OCMArg any]];
	[[componentMock expect] textDidEndEditing:[OCMArg any]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidEndEditingNotification object:_component.uiComponent];
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidChangeNotification object:_component.uiComponent];
	
	[componentMock verify];
}

- (void)testControlValidatesOnEndEditingWithValidationEventEndEditing
{
	UISlider *slider = [UISlider new];
	_component = [[REDValidationComponent alloc] initWithIdentifier:nil initialValue:nil validationEvent:REDValidationEventEndEditing rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}]];
	_component.uiComponent = slider;
	
	// sendActionsForControlEvents: doesn't work while unit testing, so verify target/events instead
	NSSet *targets = slider.allTargets;
	XCTAssertEqual(targets.count, 1);
	
	id target = targets.allObjects.firstObject;
	XCTAssertEqualObjects(target, _component);
	XCTAssertEqual([slider actionsForTarget:target forControlEvent:UIControlEventEditingDidEnd].count, 1);
	XCTAssertEqual([slider actionsForTarget:target forControlEvent:UIControlEventValueChanged].count, 0);
}

- (void)testControlValidatesOnAllEventsWithValidationEventDefault
{
	UISlider *slider = [UISlider new];
	_component.uiComponent = slider;
	
	// sendActionsForControlEvents: doesn't work while unit testing, so verify target/events instead
	NSSet *targets = slider.allTargets;
	XCTAssertEqual(targets.count, 1);
	
	id target = targets.allObjects.firstObject;
	XCTAssertEqualObjects(target, _component);
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
	
	REDValidationComponent *component = [[REDValidationComponent alloc] initWithIdentifier:nil initialValue:nil validationEvent:REDValidationEventDefault rule:rule];
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
	
	REDValidationComponent *component = [[REDValidationComponent alloc] initWithIdentifier:nil initialValue:nil validationEvent:REDValidationEventDefault rule:rule];
	
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
	
	REDValidationComponent *component = [[REDValidationComponent alloc] initWithIdentifier:nil initialValue:nil validationEvent:REDValidationEventDefault rule:rule];
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
	
	REDValidationComponent *component = [[REDValidationComponent alloc] initWithIdentifier:nil initialValue:nil validationEvent:REDValidationEventDefault rule:rule];
	component.uiComponent = textField;
	
	XCTAssertTrue(rule.allowDefault);
	XCTAssertNotEqualObjects([component.uiComponent validatedValue], kUITextFieldDefaultValue);
	
	XCTAssertEqual([component evaluateDefaultValidity], component.valid);
}

@end
