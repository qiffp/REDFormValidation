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
#import "REDValidatableComponent.h"

@interface REDValidationRuleTests : XCTestCase
@end

@implementation REDValidationRuleTests

#pragma mark - validate

- (void)testRulePassingValidation
{
	REDValidationRule *rule = [REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}];
	XCTAssertEqual([rule validate:nil], REDValidationResultValid);
}

- (void)testRuleFailingValidation
{
	REDValidationRule *rule = [REDValidationRule ruleWithBlock:^BOOL(id value) {
		return NO;
	}];
	XCTAssertEqual([rule validate:nil], REDValidationResultInvalid);
}

- (void)testRuleFailsValidationWithoutABlock
{
	REDValidationRule *rule = [REDValidationRule ruleWithBlock:nil];
	XCTAssertEqual([rule validate:nil], REDValidationResultInvalid);
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
	[[delegateMock expect] validationRule:rule completedNetworkValidationOfComponent:nil withResult:REDValidationResultValid error:nil];
	
	[rule validate:nil];
	
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
	[[delegateMock expect] validationRule:rule completedNetworkValidationOfComponent:nil withResult:REDValidationResultInvalid error:nil];
	
	[rule validate:nil];
	
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
	
	XCTAssertEqual([rule validate:nil], REDValidationResultPending, @"Validation should be pending until completion is called");
	[self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testNetworkRuleFailsValidationWithoutABlock
{
	REDNetworkValidationRule *rule = [REDNetworkValidationRule ruleWithBlock:nil];
	XCTAssertEqual([rule validate:nil], REDValidationResultInvalid);
}

#pragma mark - allowDefault

- (void)testValidateReturnsDefaultValidIfRuleAllowsDefaultAndValueIsDefault
{
	REDValidationRule *rule = [REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}];
	rule.allowDefault = YES;
	
	UITextField *textField = [UITextField new];
	
	XCTAssertEqual([rule validate:textField], REDValidationResultDefaultValid, @"Validation should not have run since validated value is default value and rule allows default");
}

- (void)testValidateRunsValidationIfRuleAllowsDefaultAndValueIsNotDefault
{
	REDValidationRule *rule = [REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}];
	rule.allowDefault = YES;
	
	UITextField *textField = [UITextField new];
	textField.text = @"test";
	
	XCTAssertEqual([rule validate:textField], REDValidationResultValid, @"Validation should have run and passed");
}

- (void)testValidateReturnsDefaultValidIfNetworkRuleAllowsDefaultAndValueIsDefault
{
	REDNetworkValidationRule *rule = [REDNetworkValidationRule ruleWithBlock:^NSURLSessionTask *(id value, REDNetworkValidationRuleResultBlock completion) {
		NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:@"http://localhost"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
			completion(YES, nil);
		}];
		[task resume];
		return task;
	}];
	rule.allowDefault = YES;
	
	UITextField *textField = [UITextField new];
	
	XCTAssertEqual([rule validate:textField], REDValidationResultDefaultValid, @"Validation should not have run since validated value is default value and rule allows default");
}

- (void)testValidateNotifiesDelegateIfNetworkRuleAllowsDefaultAndValueIsDefault
{
	REDNetworkValidationRule *rule = [REDNetworkValidationRule ruleWithBlock:^NSURLSessionTask *(id value, REDNetworkValidationRuleResultBlock completion) {
		NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:@"http://localhost"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
			completion(YES, nil);
		}];
		[task resume];
		return task;
	}];
	rule.allowDefault = YES;
	
	UITextField *textField = [UITextField new];
	
	id delegateMock = [OCMockObject niceMockForProtocol:@protocol(REDNetworkValidationRuleDelegate)];
	rule.delegate = delegateMock;
	[[delegateMock expect] validationRule:rule completedNetworkValidationOfComponent:textField withResult:REDValidationResultDefaultValid error:nil];
	
	[rule validate:textField];
	
	[delegateMock verify];
}

- (void)testValidateRunsValidationIfNetworkRuleAllowsDefaultAndValueIsNotDefault
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
	rule.allowDefault = YES;
	
	UITextField *textField = [UITextField new];
	textField.text = @"test";
	
	id delegateMock = [OCMockObject niceMockForProtocol:@protocol(REDNetworkValidationRuleDelegate)];
	rule.delegate = delegateMock;
	[[delegateMock expect] validationRule:rule completedNetworkValidationOfComponent:textField withResult:REDValidationResultValid error:nil];
	
	[rule validate:textField];
	
	[self waitForExpectationsWithTimeout:5.0 handler:nil];
	[delegateMock verify];
}

@end
