//
//  REDValidationTests.m
//  REDFormValidation
//
//  Created by Sam Dye on 2016-03-12.
//  Copyright © 2016 Sam Dye. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import "REDValidation.h"

@interface REDValidation (TestExpose)
- (void)uiComponentTextDidChange:(NSNotification *)notification;
- (void)uiComponentTextDidEndEditing:(NSNotification *)notification;
@end

@interface REDValidation (TestHelper)
@property (nonatomic, assign, readwrite) REDValidationResult valid;
@end

@implementation REDValidation (TestHelper)

- (void)setValid:(REDValidationResult)valid
{
	[self setValue:@(valid) forKey:@"_valid"];
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
	_validation = [REDValidation validationWithIdentifier:nil initialValue:@"hi" validationEvent:REDValidationEventDefault rule:[REDValidationRule ruleWithBlock:^BOOL(NSString *value) {
		return value.length > 4;
	}]];
	_validation.valid = REDValidationResultUnvalidated;
	XCTAssertEqual([_validation validate], REDValidationResultInvalid);
	
	_validation = [REDValidation validationWithIdentifier:nil initialValue:@"hello" validationEvent:REDValidationEventDefault rule:[REDValidationRule ruleWithBlock:^BOOL(NSString *value) {
		return value.length > 4;
	}]];
	_validation.valid = REDValidationResultUnvalidated;
	XCTAssertEqual([_validation validate], REDValidationResultValid);
}

- (void)testValidateDoesNotValidateInitialValueIfValidationHasNoUIComponentAndIsValidated
{
	_validation = [REDValidation validationWithIdentifier:nil initialValue:@"hi" validationEvent:REDValidationEventDefault rule:[REDValidationRule ruleWithBlock:^BOOL(NSString *value) {
		return value.length > 4;
	}]];
	_validation.valid = REDValidationResultValid;
	XCTAssertEqual([_validation validate], REDValidationResultValid);
}

#pragma mark - validationEvent

- (void)testTextFieldValidatesOnEndEditingWithValidationEventEndEditing
{
	_validation = [REDValidation validationWithIdentifier:nil initialValue:nil validationEvent:REDValidationEventEndEditing rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}]];
	_validation.uiComponent = _textField;
	
	id validationMock = [OCMockObject partialMockForObject:_validation];
	[[validationMock reject] uiComponentTextDidChange:[OCMArg any]];
	[[validationMock expect] uiComponentTextDidEndEditing:[OCMArg any]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidEndEditingNotification object:_validation.uiComponent];
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification object:_validation.uiComponent];
	
	[validationMock verify];
}

- (void)testTextFieldValidatesOnAllEventsWithValidationEventDefault
{
	id validationMock = [OCMockObject partialMockForObject:_validation];
	[[validationMock expect] uiComponentTextDidChange:[OCMArg any]];
	[[validationMock expect] uiComponentTextDidEndEditing:[OCMArg any]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidEndEditingNotification object:_validation.uiComponent];
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification object:_validation.uiComponent];
	
	[validationMock verify];
}

- (void)testTextViewValidatesOnEndEditingWithValidationEventEndEditing
{
	UITextView *textView = [UITextView new];
	textView.text = @"test";
	_validation = [REDValidation validationWithIdentifier:nil initialValue:nil validationEvent:REDValidationEventEndEditing rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}]];
	_validation.uiComponent = textView;
	
	id validationMock = [OCMockObject partialMockForObject:_validation];
	[[validationMock reject] uiComponentTextDidChange:[OCMArg any]];
	[[validationMock expect] uiComponentTextDidEndEditing:[OCMArg any]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidEndEditingNotification object:_validation.uiComponent];
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidChangeNotification object:_validation.uiComponent];
	
	[validationMock verify];
}

- (void)testTextViewValidatesOnAllEventsWithValidationEventDefault
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

- (void)testControlValidatesOnEndEditingWithValidationEventEndEditing
{
	UISlider *slider = [UISlider new];
	_validation = [REDValidation validationWithIdentifier:nil initialValue:nil validationEvent:REDValidationEventEndEditing rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}]];
	_validation.uiComponent = slider;
	
	// sendActionsForControlEvents: doesn't work while unit testing, so verify target/events instead
	NSSet *targets = slider.allTargets;
	XCTAssertEqual(targets.count, 1);
	
	id target = targets.allObjects.firstObject;
	XCTAssertEqualObjects(target, _validation);
	XCTAssertEqual([slider actionsForTarget:target forControlEvent:UIControlEventEditingDidEnd].count, 1);
	XCTAssertEqual([slider actionsForTarget:target forControlEvent:UIControlEventValueChanged].count, 0);
}

- (void)testControlValidatesOnAllEventsWithValidationEventDefault
{
	UISlider *slider = [UISlider new];
	_validation.uiComponent = slider;
	
	// sendActionsForControlEvents: doesn't work while unit testing, so verify target/events instead
	NSSet *targets = slider.allTargets;
	XCTAssertEqual(targets.count, 1);
	
	id target = targets.allObjects.firstObject;
	XCTAssertEqualObjects(target, _validation);
	XCTAssertEqual([slider actionsForTarget:target forControlEvent:UIControlEventEditingDidEnd].count, 1);
	XCTAssertEqual([slider actionsForTarget:target forControlEvent:UIControlEventValueChanged].count, 1);
}

#pragma mark - evaluateDefaultValidity

- (void)testEvaluateDefaultValidityReturnsDefaultValidIfValidationAllowsDefaultAndUIComponentValueIsDefaultValue
{
	UITextField *textField = [UITextField new];
	
	REDValidation *validation = [REDValidation validationWithIdentifier:nil initialValue:nil validationEvent:REDValidationEventDefault rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}]];
	validation.allowDefault = YES;
	validation.uiComponent = textField;
	
	XCTAssertTrue(validation.allowDefault);
	XCTAssertEqualObjects([validation.uiComponent validatedValue], kUITextFieldDefaultValue);
	
	XCTAssertEqual([validation evaluateDefaultValidity], REDValidationResultDefaultValid);
}

- (void)testEvaluateDefaultValidityReturnsDefaultValidIfValidationAllowsDefaultValidAndUIComponentIsNil
{
	REDValidation *validation = [REDValidation validationWithIdentifier:nil initialValue:nil validationEvent:REDValidationEventDefault rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}]];
	validation.allowDefault = YES;
	
	XCTAssertTrue(validation.allowDefault);
	XCTAssertNil(validation.uiComponent);
	
	XCTAssertEqual([validation evaluateDefaultValidity], REDValidationResultDefaultValid);
}

- (void)testEvaluateDefaultValidityReturnsExistingValidValueIfValidationDoesNotAllowDefault
{
	UITextField *textField = [UITextField new];
	
	REDValidation *validation = [REDValidation validationWithIdentifier:nil initialValue:nil validationEvent:REDValidationEventDefault rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}]];
	validation.uiComponent = textField;
	
	XCTAssertFalse(validation.allowDefault);
	XCTAssertEqualObjects([validation.uiComponent validatedValue], kUITextFieldDefaultValue);
	
	XCTAssertEqual([validation evaluateDefaultValidity], validation.valid);
}

- (void)testEvaluateDefaultValidityReturnsExistingValidValueIfUIComponentValueIsNotDefaultValue
{
	UITextField *textField = [UITextField new];
	textField.text = @"test";
	
	REDValidation *validation = [REDValidation validationWithIdentifier:nil initialValue:nil validationEvent:REDValidationEventDefault rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}]];
	validation.allowDefault = YES;
	validation.uiComponent = textField;
	
	XCTAssertTrue(validation.allowDefault);
	XCTAssertNotEqualObjects([validation.uiComponent validatedValue], kUITextFieldDefaultValue);
	
	XCTAssertEqual([validation evaluateDefaultValidity], validation.valid);
}

@end
