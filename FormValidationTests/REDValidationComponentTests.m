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
@property (nonatomic, assign, readwrite) BOOL valid;
@property (nonatomic, assign, readwrite) BOOL validated;
@end

@implementation REDValidationComponent (TestHelper)

- (void)setValid:(BOOL)valid
{
	[self setValue:@(valid) forKey:@"_valid"];
}

- (void)setValidated:(BOOL)validated
{
	[self setValue:@(validated) forKey:@"_validated"];
}

- (BOOL)validated
{
	return [[self valueForKey:@"_validated"] boolValue];
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
	
	_component = [[REDValidationComponent alloc] initWithValidationEvent:REDValidationEventAll rule:[REDValidationRule ruleWithBlock:^BOOL(UIView *component) {
		return YES;
	}]];
	_component.uiComponent = _textField;
	_component.delegate = _delegate;
}

- (void)tearDown
{
	[_delegate verify];
	_component = nil;
    [super tearDown];
}

- (void)testValidReturnsFalseIfNotAlreadyValidated
{
	XCTAssertFalse(_component.validated, @"Component should not be validated");
	XCTAssertFalse(_component.valid, @"Component should not be valid");
}

- (void)testValidReturnsPreviousValidationResultIfAlreadyValidated
{
	[[_delegate reject] validationComponent:[OCMArg any] didValidateUIComponent:[OCMArg any] result:[OCMArg any]];
	_component.validated = YES;
	
	_component.valid = YES;
	XCTAssertTrue(_component.valid, @"Component should be valid");
	
	_component.valid = NO;
	XCTAssertFalse(_component.valid, @"Component should not be valid");
}

- (void)testValidateReturnsTrueIfShouldValidateIsFalse
{
	_component.shouldValidate = NO;
	_component.valid = NO;
	XCTAssertTrue([_component validate], @"Validate should return true if shouldValidate is false");
}

- (void)testValidateReturnsValidWithNoUIComponent
{
	_component.uiComponent = nil;
	
	_component.valid = YES;
	XCTAssertTrue([_component validate], @"Validate should return previous valid value if there is no uiComponent");
	
	_component.valid = NO;
	XCTAssertFalse([_component validate], @"Validate should return previous valid value if there is no uiCompnent");
}

- (void)testValidatesOnBeginEditingWithValidationEventBeginEditing
{
	_component = [[REDValidationComponent alloc] initWithValidationEvent:REDValidationEventBeginEditing rule:[REDValidationRule ruleWithBlock:^BOOL(UIView *component) {
		return YES;
	}]];
	_component.uiComponent = _textField;
	_component.delegate = _delegate;
	
	__block NSUInteger callCount = 0;
	[[[_delegate expect] andDo:^(NSInvocation *invocation) {
		callCount++;
	}] validationComponent:_component didValidateUIComponent:_component.uiComponent result:[OCMArg any]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidBeginEditingNotification object:_component.uiComponent];
	XCTAssertEqual(callCount, 1, @"callCount should increment after begin editing");
	
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidEndEditingNotification object:_component.uiComponent];
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification object:_component.uiComponent];
	XCTAssertEqual(callCount, 1, @"callCount should not increase after other notifications");
}

- (void)testValidatesOnEndEditingWithValidationEventEndEditing
{
	_component = [[REDValidationComponent alloc] initWithValidationEvent:REDValidationEventEndEditing rule:[REDValidationRule ruleWithBlock:^BOOL(UIView *component) {
		return YES;
	}]];
	_component.uiComponent = _textField;
	_component.delegate = _delegate;
	
	__block NSUInteger callCount = 0;
	[[[_delegate expect] andDo:^(NSInvocation *invocation) {
		callCount++;
	}] validationComponent:_component didValidateUIComponent:_component.uiComponent result:[OCMArg any]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidEndEditingNotification object:_component.uiComponent];
	XCTAssertEqual(callCount, 1, @"callCount should increment after end editing notification");
	
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidBeginEditingNotification object:_component.uiComponent];
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification object:_component.uiComponent];
	XCTAssertEqual(callCount, 1, @"callCount should not increase after other notifications");
}

- (void)testValidatesOnChangeWithValidationEventChange
{
	_component = [[REDValidationComponent alloc] initWithValidationEvent:REDValidationEventChange rule:[REDValidationRule ruleWithBlock:^BOOL(UIView *component) {
		return YES;
	}]];
	_component.uiComponent = _textField;
	_component.delegate = _delegate;
	
	__block NSUInteger callCount = 0;
	[[[_delegate expect] andDo:^(NSInvocation *invocation) {
		callCount++;
	}] validationComponent:_component didValidateUIComponent:_component.uiComponent result:[OCMArg any]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification object:_component.uiComponent];
	XCTAssertEqual(callCount, 1, @"callCount should increment after change notification");
	
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidBeginEditingNotification object:_component.uiComponent];
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidEndEditingNotification object:_component.uiComponent];
	XCTAssertEqual(callCount, 1, @"callCount should not increase after other notifications");
}

- (void)testValidatesOnAllEventsWithValidationEventAll
{
	[[_delegate expect] validationComponent:_component didValidateUIComponent:_component.uiComponent result:YES];
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidBeginEditingNotification object:_component.uiComponent];
	[_delegate verify];
	
	[[_delegate expect] validationComponent:_component didValidateUIComponent:_component.uiComponent result:YES];
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidEndEditingNotification object:_component.uiComponent];
	[_delegate verify];
	
	[[_delegate expect] validationComponent:_component didValidateUIComponent:_component.uiComponent result:YES];
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification object:_component.uiComponent];
	[_delegate verify];
}

- (void)testComponentIsValidatedAfterValidating
{
	[_component validate];
	XCTAssertTrue(_component.validated, @"Component should be validated after validating");
}

- (void)testComponentIsNotValidatedUntilNetworkValidationCompletes
{
	XCTestExpectation *validationExpectation = [self expectationWithDescription:@"validated"];
	_component = [[REDValidationComponent alloc] initWithValidationEvent:REDValidationEventAll rule:[REDNetworkValidationRule ruleWithBlock:^NSURLSessionTask *(UIView *component, REDNetworkValidationResultBlock completion) {
		NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:@"http://localhost"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
			completion(NO, nil);
			
			[validationExpectation fulfill];
		}];
		[task resume];
		return task;
	}]];
	_component.uiComponent = _textField;
	
	[_component validate];
	XCTAssertFalse(_component.validated, @"Component should not be validated until network validation completes");
	
	[self waitForExpectationsWithTimeout:5.0 handler:nil];
	XCTAssertTrue(_component.validated, @"Component should be validated once network validation completes");
}

@end
