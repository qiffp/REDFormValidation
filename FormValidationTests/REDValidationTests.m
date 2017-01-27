//
//  REDValidationTests.m
//  REDFormValidation
//
//  Created by Sam Dye on 2016-03-12.
//  Copyright © 2016 Sam Dye. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import "REDValidation+Private.h"

@interface REDValidation (TestExpose)
- (void)uiComponentValueChanged;
- (void)uiComponentDidEndEditing;
- (void)uiComponentValueChanged:(NSObject<REDValidatableComponent> *)component;
- (void)uiComponentDidEndEditing:(NSObject<REDValidatableComponent> *)component;
- (void)uiComponentTextDidChange:(NSNotification *)notification;
- (void)uiComponentTextDidEndEditing:(NSNotification *)notification;
@end

@interface REDValidation (TestHelper)
@property (nonatomic, assign, readwrite) REDValidationResult valid;
@property (nonatomic, assign, readwrite) BOOL requiresValidation;
@end

@implementation REDValidation (TestHelper)

- (void)setValid:(REDValidationResult)valid
{
	[self setValue:@(valid) forKey:@"_valid"];
}

- (BOOL)requiresValidation
{
	return [self valueForKey:@"_requiresValidation"];
}

- (void)setRequiresValidation:(BOOL)requiresValidation
{
	[self setValue:@(requiresValidation) forKey:@"_requiresValidation"];
}

@end

@interface REDValidationTests : XCTestCase
@end

@implementation REDValidationTests {
	UITextField *_textField;
	REDValidation *_validation;
}

- (void)setUp
{
    [super setUp];
	
	_textField = [UITextField new];
	_textField.text = @"test";
	
	_validation = [REDValidation validationWithIdentifier:nil rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}]];
	_validation.uiComponent = _textField;
}

- (void)tearDown
{
	_textField = nil;
	_validation = nil;
	
    [super tearDown];
}

#pragma mark - valid

- (void)testNewValidationIsUnvalidated
{
	XCTAssertEqual(_validation.valid, REDValidationResultUnvalidated);
}

#pragma mark - validate

- (void)testValidateReturnsValidResultIfShouldValidateIsFalse
{
	_validation.shouldValidate = NO;
	_validation.valid = REDValidationResultUnvalidated;
	XCTAssertEqual([_validation validate], REDValidationResultValid);
}

- (void)testValidateValidatesUIComponentIfThereIsOne
{
	XCTAssertNotNil(_validation.uiComponent);
	XCTAssertTrue(_validation.shouldValidate);
	XCTAssertEqual([_validation validate], REDValidationResultValid);
}

- (void)testValidateReturnsExistingValidValueIfValidationHasNoUIComponentAndHasNoInitialValue
{
	_validation.uiComponent = nil;
	
	_validation.valid = REDValidationResultValid;
	XCTAssertEqual([_validation validate], REDValidationResultValid);
	
	_validation.valid = REDValidationResultInvalid;
	XCTAssertEqual([_validation validate], REDValidationResultInvalid);
}

- (void)testValidateValidatesInitialValueIfValidationHasNoUIComponentAndIsUnvalidated
{
	_validation = [REDValidation validationWithIdentifier:nil initialValue:@"hi" allowDefault:NO validationEvent:REDValidationEventAll rule:[REDValidationRule ruleWithBlock:^BOOL(NSString *value) {
		return value.length > 4;
	}]];
	_validation.valid = REDValidationResultUnvalidated;
	XCTAssertEqual([_validation validate], REDValidationResultInvalid);
	
	_validation = [REDValidation validationWithIdentifier:nil initialValue:@"hello" allowDefault:NO validationEvent:REDValidationEventAll rule:[REDValidationRule ruleWithBlock:^BOOL(NSString *value) {
		return value.length > 4;
	}]];
	_validation.valid = REDValidationResultUnvalidated;
	XCTAssertEqual([_validation validate], REDValidationResultValid);
}

- (void)testValidateDoesNotValidateInitialValueIfValidationHasNoUIComponentAndIsValidated
{
	_validation = [REDValidation validationWithIdentifier:nil initialValue:@"hi" allowDefault:NO validationEvent:REDValidationEventAll rule:[REDValidationRule ruleWithBlock:^BOOL(NSString *value) {
		return value.length > 4;
	}]];
	_validation.valid = REDValidationResultValid;
	XCTAssertEqual([_validation validate], REDValidationResultValid);
}

#pragma mark - validationEvent

- (void)testTextFieldWithValidationEventEndEditingRespondsToAllNotifications
{
	_validation = [REDValidation validationWithIdentifier:nil initialValue:nil allowDefault:NO validationEvent:REDValidationEventEndEditing rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}]];
	_validation.uiComponent = _textField;
	
	id validationMock = [OCMockObject partialMockForObject:_validation];
	[[validationMock expect] uiComponentTextDidChange:[OCMArg any]];
	[[validationMock expect] uiComponentTextDidEndEditing:[OCMArg any]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidEndEditingNotification object:_validation.uiComponent];
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification object:_validation.uiComponent];
	
	[validationMock verify];
}

- (void)testTextFieldWithValidationEventAllRespondsToAllNotifications
{
	id validationMock = [OCMockObject partialMockForObject:_validation];
	[[validationMock expect] uiComponentTextDidChange:[OCMArg any]];
	[[validationMock expect] uiComponentTextDidEndEditing:[OCMArg any]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidEndEditingNotification object:_validation.uiComponent];
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification object:_validation.uiComponent];
	
	[validationMock verify];
}

- (void)testTextViewWithValidationEventEndEditingRespondsToAllNotifications
{
	UITextView *textView = [UITextView new];
	textView.text = @"test";
	_validation = [REDValidation validationWithIdentifier:nil initialValue:nil allowDefault:NO validationEvent:REDValidationEventEndEditing rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}]];
	_validation.uiComponent = textView;
	
	id validationMock = [OCMockObject partialMockForObject:_validation];
	[[validationMock expect] uiComponentTextDidChange:[OCMArg any]];
	[[validationMock expect] uiComponentTextDidEndEditing:[OCMArg any]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidEndEditingNotification object:_validation.uiComponent];
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidChangeNotification object:_validation.uiComponent];
	
	[validationMock verify];
}

- (void)testTextViewWithValidationEventAllRespondsToAllNotifications
{
	UITextView *textView = [UITextView new];
	textView.text = @"test";
	_validation.uiComponent = textView;
	
	id validationMock = [OCMockObject partialMockForObject:_validation];
	[[validationMock expect] uiComponentTextDidChange:[OCMArg any]];
	[[validationMock expect] uiComponentTextDidEndEditing:[OCMArg any]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidEndEditingNotification object:_validation.uiComponent];
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidChangeNotification object:_validation.uiComponent];
	
	[validationMock verify];
}

// sendActionsForControlEvents: doesn't work while unit testing, so verify target/events instead

- (void)testControlWithValidationEventEndEditingHasActionsForAllEvents
{
	UISlider *slider = [UISlider new];
	_validation = [REDValidation validationWithIdentifier:nil initialValue:nil allowDefault:NO validationEvent:REDValidationEventEndEditing rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}]];
	_validation.uiComponent = slider;
	
	id validationDelegate = [OCMockObject niceMockForProtocol:@protocol(REDValidationDelegate)];
	_validation.delegate = validationDelegate;
	
	NSSet *targets = slider.allTargets;
	XCTAssertEqual(targets.count, 1);

	id target = targets.allObjects.firstObject;
	XCTAssertEqualObjects(target, _validation);
	XCTAssertEqual([slider actionsForTarget:target forControlEvent:UIControlEventEditingDidEnd].count, 1);
	XCTAssertEqual([slider actionsForTarget:target forControlEvent:UIControlEventValueChanged].count, 1);
}

- (void)testControlWithValidationEventAllHasActionsForAllEvents
{
	UISlider *slider = [UISlider new];
	_validation = [REDValidation validationWithIdentifier:nil initialValue:nil allowDefault:NO validationEvent:REDValidationEventAll rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}]];
	_validation.uiComponent = slider;
	
	id validationDelegate = [OCMockObject niceMockForProtocol:@protocol(REDValidationDelegate)];
	_validation.delegate = validationDelegate;
	
	NSSet *targets = slider.allTargets;
	XCTAssertEqual(targets.count, 1);
	
	id target = targets.allObjects.firstObject;
	XCTAssertEqualObjects(target, _validation);
	XCTAssertEqual([slider actionsForTarget:target forControlEvent:UIControlEventEditingDidEnd].count, 1);
	XCTAssertEqual([slider actionsForTarget:target forControlEvent:UIControlEventValueChanged].count, 1);
}

#pragma mark - uiComponentValueChanged

- (void)testValueChangedSetsRequiresValidation
{
	_validation.requiresValidation = NO;
	[_validation uiComponentValueChanged];
	XCTAssertTrue(_validation.requiresValidation);
}

#pragma mark - uiComponentDidEndEditing

- (void)testDidEndEditingValidatesIfRequiresValidation
{
	_validation.requiresValidation = YES;
	
	id validationDelegateMock = [OCMockObject niceMockForProtocol:@protocol(REDValidationDelegate)];
	[[validationDelegateMock expect] validation:_validation didValidateUIComponent:_textField result:REDValidationResultValid error:[OCMArg any]];
	_validation.delegate = validationDelegateMock;
	
	[_validation uiComponentDidEndEditing];
	
	[validationDelegateMock verify];
}

- (void)testDidEndEditingDoesNotValidateIfDoesNotRequireValidation
{
	_validation.requiresValidation = NO;
	
	id validationDelegateMock = [OCMockObject niceMockForProtocol:@protocol(REDValidationDelegate)];
	[[validationDelegateMock reject] validation:_validation didValidateUIComponent:_textField result:REDValidationResultValid error:[OCMArg any]];
	_validation.delegate = validationDelegateMock;
	
	[_validation uiComponentDidEndEditing];
	
	[validationDelegateMock verify];
}

#pragma mark - evaluateDefaultValidity

- (void)testEvaluateDefaultValidityReturnsDefaultValidIfValidationAllowsDefaultAndUIComponentValueIsDefaultValue
{
	UITextField *textField = [UITextField new];
	
	REDValidation *validation = [REDValidation validationWithIdentifier:nil initialValue:nil allowDefault:YES validationEvent:REDValidationEventAll rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}]];
	validation.uiComponent = textField;
	
	XCTAssertTrue(validation.allowDefault);
	XCTAssertEqualObjects(validation.uiComponent.validatedValue, kUITextFieldDefaultValue);
	
	XCTAssertEqual([validation evaluateDefaultValidity], REDValidationResultDefaultValid);
}

- (void)testEvaluateDefaultValidityReturnsDefaultValidIfValidationAllowsDefaultValidAndUIComponentIsNil
{
	REDValidation *validation = [REDValidation validationWithIdentifier:nil initialValue:nil allowDefault:YES validationEvent:REDValidationEventAll rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}]];
	
	XCTAssertTrue(validation.allowDefault);
	XCTAssertNil(validation.uiComponent);
	
	XCTAssertEqual([validation evaluateDefaultValidity], REDValidationResultDefaultValid);
}

- (void)testEvaluateDefaultValidityReturnsExistingValidValueIfValidationDoesNotAllowDefault
{
	UITextField *textField = [UITextField new];
	
	REDValidation *validation = [REDValidation validationWithIdentifier:nil initialValue:nil allowDefault:NO validationEvent:REDValidationEventAll rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}]];
	validation.uiComponent = textField;
	
	XCTAssertFalse(validation.allowDefault);
	XCTAssertEqualObjects(validation.uiComponent.validatedValue, kUITextFieldDefaultValue);
	
	XCTAssertEqual([validation evaluateDefaultValidity], validation.valid);
}

- (void)testEvaluateDefaultValidityReturnsExistingValidValueIfUIComponentValueIsNotDefaultValue
{
	UITextField *textField = [UITextField new];
	textField.text = @"test";
	
	REDValidation *validation = [REDValidation validationWithIdentifier:nil initialValue:nil allowDefault:YES validationEvent:REDValidationEventAll rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}]];
	validation.uiComponent = textField;
	
	XCTAssertTrue(validation.allowDefault);
	XCTAssertNotEqualObjects(validation.uiComponent.validatedValue, kUITextFieldDefaultValue);
	
	XCTAssertEqual([validation evaluateDefaultValidity], validation.valid);
}

@end
