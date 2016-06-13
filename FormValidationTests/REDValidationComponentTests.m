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
- (BOOL)validate;
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
	id _delegate;
}

- (void)setUp
{
    [super setUp];
	
	_delegate = [OCMockObject niceMockForProtocol:@protocol(REDValidationComponentDelegate)];
	_textField = [UITextField new];
	
	_component = [[REDValidationComponent alloc] initWithValidationEvent:REDValidationEventAll rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
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

#pragma mark - reset

- (void)testResetReinitializesValid
{
	_component.valid = REDValidationResultValid;
	[_component reset];
	XCTAssertEqual(_component.valid, REDValidationResultUnvalidated, @"Component should be unvalidated");
}

#pragma mark - validate

- (void)testValidateReturnsValidResultIfShouldValidateIsFalse
{
	_component.shouldValidate = NO;
	_component.valid = REDValidationResultUnvalidated;
	XCTAssertEqual([_component validate], REDValidationResultValid, @"Validate should return valid if shouldValidate is false");
}

- (void)testValidateReturnsExistingValidValueWithNoUIComponent
{
	_component.uiComponent = nil;
	
	_component.valid = REDValidationResultValid;
	XCTAssertEqual([_component validate], REDValidationResultValid, @"Validate should return previous valid value if there is no uiComponent");
	
	_component.valid = REDValidationResultInvalid;
	XCTAssertEqual([_component validate], REDValidationResultInvalid, @"Validate should return previous valid value if there is no uiCompnent");
}

#pragma mark - validationEvent

- (void)testValidatesOnBeginEditingWithValidationEventBeginEditing
{
	_component = [[REDValidationComponent alloc] initWithValidationEvent:REDValidationEventBeginEditing rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}]];
	_component.uiComponent = _textField;
	_component.delegate = _delegate;
	
	__block NSUInteger callCount = 0;
	[[[_delegate stub] andDo:^(NSInvocation *invocation) {
		callCount++;
	}] validationComponent:[OCMArg any] didValidateUIComponent:[OCMArg any] result:REDValidationResultValid];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidBeginEditingNotification object:_component.uiComponent];
	XCTAssertEqual(callCount, 1, @"callCount should increment after begin editing");
	
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidEndEditingNotification object:_component.uiComponent];
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification object:_component.uiComponent];
	XCTAssertEqual(callCount, 1, @"callCount should not increase after other notifications");
}

- (void)testValidatesOnEndEditingWithValidationEventEndEditing
{
	_component = [[REDValidationComponent alloc] initWithValidationEvent:REDValidationEventEndEditing rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}]];
	_component.uiComponent = _textField;
	_component.delegate = _delegate;
	
	__block NSUInteger callCount = 0;
	[[[_delegate stub] andDo:^(NSInvocation *invocation) {
		callCount++;
	}] validationComponent:[OCMArg any] didValidateUIComponent:[OCMArg any] result:REDValidationResultValid];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidEndEditingNotification object:_component.uiComponent];
	XCTAssertEqual(callCount, 1, @"callCount should increment after end editing notification");
	
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidBeginEditingNotification object:_component.uiComponent];
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification object:_component.uiComponent];
	XCTAssertEqual(callCount, 1, @"callCount should not increase after other notifications");
}

- (void)testValidatesOnChangeWithValidationEventChange
{
	_component = [[REDValidationComponent alloc] initWithValidationEvent:REDValidationEventChange rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}]];
	_component.uiComponent = _textField;
	_component.delegate = _delegate;
	
	__block NSUInteger callCount = 0;
	[[[_delegate stub] andDo:^(NSInvocation *invocation) {
		callCount++;
	}] validationComponent:[OCMArg any] didValidateUIComponent:[OCMArg any] result:REDValidationResultValid];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification object:_component.uiComponent];
	XCTAssertEqual(callCount, 1, @"callCount should increment after change notification");
	
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidBeginEditingNotification object:_component.uiComponent];
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidEndEditingNotification object:_component.uiComponent];
	XCTAssertEqual(callCount, 1, @"callCount should not increase after other notifications");
}

- (void)testValidatesOnAllEventsWithValidationEventAll
{
	__block NSUInteger callCount = 0;
	[[[_delegate stub] andDo:^(NSInvocation *invocation) {
		callCount++;
	}] validationComponent:[OCMArg any] didValidateUIComponent:[OCMArg any] result:REDValidationResultValid];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidBeginEditingNotification object:_component.uiComponent];
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidEndEditingNotification object:_component.uiComponent];
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification object:_component.uiComponent];
	
	XCTAssertEqual(callCount, 3, @"callCount should have been incremented for each event");
}

@end
