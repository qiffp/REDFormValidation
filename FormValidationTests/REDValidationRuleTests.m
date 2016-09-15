//
//  REDValidationRuleTests.m
//  REDFormValidation
//
//  Created by Sam Dye on 2016-03-06.
//  Copyright © 2016 Sam Dye. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import "REDValidationRuleType.h"
#import "REDValidation.h"
#import "REDValidatableComponent.h"
#import "REDValidation.h"

@interface REDValidationRuleTests : XCTestCase
@end

@implementation REDValidationRuleTests

#pragma mark - validate:allowDefault

- (void)testRulePassingValidation
{
	REDValidationRule *rule = [REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}];
	XCTAssertEqual([rule validate:nil allowDefault:NO], REDValidationResultValid);
}

- (void)testRuleFailingValidation
{
	REDValidationRule *rule = [REDValidationRule ruleWithBlock:^BOOL(id value) {
		return NO;
	}];
	XCTAssertEqual([rule validate:nil allowDefault:NO], REDValidationResultInvalid);
}

- (void)testRuleFailsValidationWithoutABlock
{
	REDValidationRule *rule = [REDValidationRule ruleWithBlock:nil];
	XCTAssertEqual([rule validate:nil allowDefault:NO], REDValidationResultInvalid);
}

- (void)testNetworkRulePassingValidation
{
	XCTestExpectation *validationExpectation = [self expectationWithDescription:@"validated"];
	REDNetworkValidationRule *rule = [REDNetworkValidationRule ruleWithBlock:^NSURLSessionTask *(id value, REDNetworkValidationRuleResultBlock completion) {
		NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:@"http://localhost"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
			completion(YES, nil);
			[validationExpectation fulfill];
		}];
		[task resume];
		return task;
	}];
	
	id delegateMock = [OCMockObject niceMockForProtocol:@protocol(REDNetworkValidationRuleDelegate)];
	rule.delegate = delegateMock;
	[[delegateMock expect] validationRule:rule completedNetworkValidationOfUIComponent:nil withResult:REDValidationResultValid error:nil];
	
	[rule validate:nil allowDefault:NO];
	
	[self waitForExpectationsWithTimeout:5.0 handler:nil];
	[delegateMock verify];
}

- (void)testNetworkRuleFailingValidation
{
	XCTestExpectation *validationExpectation = [self expectationWithDescription:@"validated"];
	REDNetworkValidationRule *rule = [REDNetworkValidationRule ruleWithBlock:^NSURLSessionTask *(id value, REDNetworkValidationRuleResultBlock completion) {
		NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:@"http://localhost"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
			completion(NO, nil);
			[validationExpectation fulfill];
		}];
		[task resume];
		return task;
	}];
	
	id delegateMock = [OCMockObject niceMockForProtocol:@protocol(REDNetworkValidationRuleDelegate)];
	rule.delegate = delegateMock;
	[[delegateMock expect] validationRule:rule completedNetworkValidationOfUIComponent:nil withResult:REDValidationResultInvalid error:nil];
	
	[rule validate:nil allowDefault:NO];
	
	[self waitForExpectationsWithTimeout:5.0 handler:nil];
	[delegateMock verify];
}

- (void)testNetworkRuleIsPendingUntilCompletionIsCalled
{
	XCTestExpectation *validationExpectation = [self expectationWithDescription:@"validated"];
	REDNetworkValidationRule *rule = [REDNetworkValidationRule ruleWithBlock:^NSURLSessionTask *(id value, REDNetworkValidationRuleResultBlock completion) {
		NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:@"http://localhost"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
			completion(YES, nil);
			[validationExpectation fulfill];
		}];
		[task resume];
		return task;
	}];
	
	XCTAssertEqual([rule validate:nil allowDefault:NO], REDValidationResultPending, @"Validation should be pending until completion is called");
	[self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testNetworkRuleFailsValidationWithoutABlock
{
	REDNetworkValidationRule *rule = [REDNetworkValidationRule ruleWithBlock:nil];
	XCTAssertEqual([rule validate:nil allowDefault:NO], REDValidationResultInvalid);
}

- (void)testValidateReturnsDefaultValidIfValidationAllowsDefaultAndValueIsDefault
{
	id<REDValidationRuleType> rule = [REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}];
	
	UITextField *textField = [UITextField new];
	
	XCTAssertEqual([rule validate:textField allowDefault:YES], REDValidationResultDefaultValid, @"Validation should not have run since validated value is default value and rule allows default");
}

- (void)testValidateRunsValidationIfValidationAllowsDefaultAndValueIsNotDefault
{
	REDValidationRule *rule = [REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}];
	
	UITextField *textField = [UITextField new];
	textField.text = @"test";
	
	XCTAssertEqual([rule validate:textField allowDefault:YES], REDValidationResultValid, @"Validation should have run and passed");
}

- (void)testValidateReturnsDefaultValidIfNetworkValidationAllowsDefaultAndValueIsDefault
{
	REDNetworkValidationRule *rule = [REDNetworkValidationRule ruleWithBlock:^NSURLSessionTask *(id value, REDNetworkValidationRuleResultBlock completion) {
		NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:@"http://localhost"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
			completion(YES, nil);
		}];
		[task resume];
		return task;
	}];
	
	UITextField *textField = [UITextField new];
	
	XCTAssertEqual([rule validate:textField allowDefault:YES], REDValidationResultDefaultValid, @"Validation should not have run since validated value is default value and rule allows default");
}

- (void)testValidateNotifiesDelegateIfNetworkValidationAllowsDefaultAndValueIsDefault
{
	REDNetworkValidationRule *rule = [REDNetworkValidationRule ruleWithBlock:^NSURLSessionTask *(id value, REDNetworkValidationRuleResultBlock completion) {
		NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:@"http://localhost"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
			completion(YES, nil);
		}];
		[task resume];
		return task;
	}];
	
	UITextField *textField = [UITextField new];
	
	id delegateMock = [OCMockObject niceMockForProtocol:@protocol(REDNetworkValidationRuleDelegate)];
	rule.delegate = delegateMock;
	[[delegateMock expect] validationRule:rule completedNetworkValidationOfUIComponent:textField withResult:REDValidationResultDefaultValid error:nil];
	
	[rule validate:textField allowDefault:YES];
	
	[delegateMock verify];
}

- (void)testValidateRunsValidationIfNetworkValidationAllowsDefaultAndValueIsNotDefault
{
	XCTestExpectation *validationExpectation = [self expectationWithDescription:@"validated"];
	REDNetworkValidationRule *rule = [REDNetworkValidationRule ruleWithBlock:^NSURLSessionTask *(id value, REDNetworkValidationRuleResultBlock completion) {
		NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:@"http://localhost"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
			completion(YES, nil);
			[validationExpectation fulfill];
		}];
		[task resume];
		return task;
	}];
	
	UITextField *textField = [UITextField new];
	textField.text = @"test";
	
	id delegateMock = [OCMockObject niceMockForProtocol:@protocol(REDNetworkValidationRuleDelegate)];
	rule.delegate = delegateMock;
	[[delegateMock expect] validationRule:rule completedNetworkValidationOfUIComponent:textField withResult:REDValidationResultValid error:nil];
	
	[rule validate:textField allowDefault:YES];
	
	[self waitForExpectationsWithTimeout:5.0 handler:nil];
	[delegateMock verify];
}

@end
