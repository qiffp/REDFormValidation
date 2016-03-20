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

@interface REDValidationComponentTestDelegate : NSObject <UITextFieldDelegate>
@property (nonatomic, assign) BOOL delegateMethodCalled;
@end

@implementation REDValidationComponentTestDelegate

// not implemented by REDValidationComponent
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	_delegateMethodCalled = YES;
	return YES;
}

// implemented by REDValidationComponent
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	_delegateMethodCalled = YES;
}

@end

@interface REDValidationComponent (TestHelper)
@property (nonatomic, readwrite, assign) BOOL valid;
@property (nonatomic, readwrite, assign) BOOL validated;
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
	REDValidationComponent *_component;
	id _delegate;
	REDValidationComponentTestDelegate *_originalDelegate;
}

- (void)setUp
{
    [super setUp];
	_delegate = [OCMockObject niceMockForProtocol:@protocol(REDValidationComponentDelegate)];
	_originalDelegate = [REDValidationComponentTestDelegate new];
	
	UITextField *textField = [UITextField new];
	textField.delegate = _originalDelegate;
	
	_component = [[REDValidationComponent alloc] initWithUIComponent:textField validateOn:REDValidationEventAll];
	_component.delegate = _delegate;
	_component.rule = [REDValidationRule ruleWithBlock:^BOOL(UIView *component) {
		return [component isKindOfClass:[UITextField class]];
	}];
}

- (void)tearDown
{
	[_delegate verify];
	_component = nil;
    [super tearDown];
}

- (void)testValidPerformsValidationIfNotAlreadyValidated
{
	[[_delegate expect] validationComponent:_component didValidateUIComponent:_component.uiComponent result:YES];
	XCTAssertTrue(_component.valid, @"Component should be valid");
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

- (void)testValidIsFalseWithNoUIComponent
{
	_component.rule = [REDValidationRule ruleWithBlock:^BOOL(UIView *component) {
		return YES;
	}];
	_component.uiComponent = nil;
	XCTAssertFalse(_component.valid, @"Component should not be valid without a UI component");
}

- (void)testSetRuleResetsValidatedState
{
	_component.validated = YES;
	
	_component.rule = [REDValidationRule ruleWithBlock:^BOOL(UIView *component) {
		return YES;
	}];
	
	XCTAssertFalse(_component.validated, @"Validated should have been reset to NO");
}

- (void)testValidatesOnBeginEditingWithValidationEventBeginEditing
{
	UITextField *textField = [UITextField new];
	_component = [[REDValidationComponent alloc] initWithUIComponent:textField validateOn:REDValidationEventBeginEditing];
	_component.delegate = _delegate;
	_component.rule = [REDValidationRule ruleWithBlock:^BOOL(UIView *component) {
		return YES;
	}];
	
	__block NSUInteger callCount = 0;
	[[[_delegate expect] andDo:^(NSInvocation *invocation) {
		callCount++;
	}] validationComponent:_component didValidateUIComponent:_component.uiComponent result:[OCMArg any]];
	
	[_component performSelector:@selector(textFieldDidBeginEditing:) withObject:_component.uiComponent];
	XCTAssertEqual(callCount, 1, @"callCount should increment after begin editing");
	
	[_component performSelector:@selector(textFieldDidEndEditing:) withObject:_component.uiComponent];
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification object:_component.uiComponent];
	XCTAssertEqual(callCount, 1, @"callCount should not increase");
}

- (void)testValidatesOnEndEditingWithValidationEventEndEditing
{
	UITextField *textField = [UITextField new];
	_component = [[REDValidationComponent alloc] initWithUIComponent:textField validateOn:REDValidationEventEndEditing];
	_component.delegate = _delegate;
	_component.rule = [REDValidationRule ruleWithBlock:^BOOL(UIView *component) {
		return YES;
	}];
	
	__block NSUInteger callCount = 0;
	[[[_delegate expect] andDo:^(NSInvocation *invocation) {
		callCount++;
	}] validationComponent:_component didValidateUIComponent:_component.uiComponent result:[OCMArg any]];
	
	[_component performSelector:@selector(textFieldDidEndEditing:) withObject:_component.uiComponent];
	XCTAssertEqual(callCount, 1, @"callCount should increment after end editing");
	
	[_component performSelector:@selector(textFieldDidBeginEditing:) withObject:_component.uiComponent];
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification object:_component.uiComponent];
	XCTAssertEqual(callCount, 1, @"callCount should not increase");
}

- (void)testValidatesOnChangeWithValidationEventChange
{
	UITextField *textField = [UITextField new];
	_component = [[REDValidationComponent alloc] initWithUIComponent:textField validateOn:REDValidationEventChange];
	_component.delegate = _delegate;
	_component.rule = [REDValidationRule ruleWithBlock:^BOOL(UIView *component) {
		return YES;
	}];
	
	__block NSUInteger callCount = 0;
	[[[_delegate expect] andDo:^(NSInvocation *invocation) {
		callCount++;
	}] validationComponent:_component didValidateUIComponent:_component.uiComponent result:[OCMArg any]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification object:_component.uiComponent];
	XCTAssertEqual(callCount, 1, @"callCount should increment after change");
	
	[_component performSelector:@selector(textFieldDidEndEditing:) withObject:_component.uiComponent];
	[_component performSelector:@selector(textFieldDidBeginEditing:) withObject:_component.uiComponent];
	XCTAssertEqual(callCount, 1, @"callCount should not increase");
}

- (void)testValidatesOnAllEventsWithValidationEventAll
{
	[[_delegate expect] validationComponent:_component didValidateUIComponent:_component.uiComponent result:YES];
	[_component performSelector:@selector(textFieldDidBeginEditing:) withObject:_component.uiComponent];
	[_delegate verify];
	
	[[_delegate expect] validationComponent:_component didValidateUIComponent:_component.uiComponent result:YES];
	[_component performSelector:@selector(textFieldDidEndEditing:) withObject:_component.uiComponent];
	[_delegate verify];
	
	[[_delegate expect] validationComponent:_component didValidateUIComponent:_component.uiComponent result:YES];
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification object:_component.uiComponent];
	[_delegate verify];
}

- (void)testComponentIsValidatedAfterValidating
{
	[_component validateUIComponent:_component.uiComponent withCallbacks:NO];
	XCTAssertTrue(_component.validated, @"Component should be validated after validating");
}

- (void)testComponentIsNotValidatedUntilNetworkValidationCompletes
{
	XCTestExpectation *validationExpectation = [self expectationWithDescription:@"validated"];
	_component.rule = [REDNetworkValidationRule ruleWithBlock:^NSURLSessionTask *(UIView *component, REDNetworkValidationResultBlock completion) {
		NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:@"http://localhost"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
			completion(NO, nil);
			
			[validationExpectation fulfill];
		}];
		[task resume];
		return task;
	}];
	
	[_component validateUIComponent:_component.uiComponent withCallbacks:NO];
	XCTAssertFalse(_component.validated, @"Component should not be validated until network validation completes");
	
	[self waitForExpectationsWithTimeout:5.0 handler:nil];
	XCTAssertTrue(_component.validated, @"Component should be validated once network validation completes");
}

- (void)testComponentRequiresValidationAfterChangingRule
{
	[_component validateUIComponent:_component.uiComponent withCallbacks:NO];
	XCTAssertTrue(_component.validated, @"Component should be validated after validating");
	
	_component.rule = nil;
	XCTAssertFalse(_component.validated, @"Component should be unvalidated after changing its rule");
}

- (void)testUnimplementedComponentDelegateMethodsGetPassedToOriginalDelegate
{
	_originalDelegate.delegateMethodCalled = NO;
	[[_delegate reject] validationComponent:[OCMArg any] didValidateUIComponent:[OCMArg any] result:[OCMArg any]];
	if ([_component respondsToSelector:@selector(textFieldShouldReturn:)]) {
		[(id<UITextFieldDelegate>)_component textFieldShouldReturn:(UITextField *)_component.uiComponent];
	}
	XCTAssertTrue(_originalDelegate.delegateMethodCalled, @"Delegate method should have been called on original delegate");
}

- (void)testImplementedComponentDelegateMethodsGetPassedToOriginalDelegate
{
	_originalDelegate.delegateMethodCalled = NO;
	[[_delegate expect] validationComponent:_component didValidateUIComponent:_component.uiComponent result:YES];
	if ([_component respondsToSelector:@selector(textFieldDidBeginEditing:)]) {
		[(id<UITextFieldDelegate>)_component textFieldDidBeginEditing:(UITextField *)_component.uiComponent];
	}
	XCTAssertTrue(_originalDelegate.delegateMethodCalled, @"Delegate method should have been called on original delegate");
}

@end
