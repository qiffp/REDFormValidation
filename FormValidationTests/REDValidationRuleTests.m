//
//  REDValidationRuleTests.m
//  REDFormValidation
//
//  Created by Sam Dye on 2016-03-06.
//  Copyright © 2016 Sam Dye. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import "REDValidationRule.h"
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
	XCTAssertEqual([rule validate:nil], REDValidationResultValid, @"Validation should succeed");
}

- (void)testRuleFailingValidation
{
	REDValidationRule *rule = [REDValidationRule ruleWithBlock:^BOOL(id value) {
		return NO;
	}];
	XCTAssertEqual([rule validate:nil], REDValidationResultInvalid, @"Validation should fail");
}

- (void)testRuleFailsValidationWithoutABlock
{
	REDValidationRule *rule = [REDValidationRule ruleWithBlock:nil];
	XCTAssertEqual([rule validate:nil], REDValidationResultInvalid, @"Validation should fail");
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
	XCTAssertEqual([rule validate:nil], REDValidationResultInvalid, @"Validation should fail");
}

#pragma mark - allowsNil

- (void)testValidateReturnsOptionalValidIfRuleAllowsNilAndValueIsNil
{
	REDValidationRule *rule = [REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}];
	rule.allowsNil = YES;
	
	id componentMock = [OCMockObject niceMockForProtocol:@protocol(REDValidatableComponent)];
	[[[componentMock stub] andReturn:nil] validatedValue];
	
	XCTAssertEqual([rule validate:componentMock], REDValidationResultOptionalValid, @"Validation should not have run since validated value is nil and rule allows nil");
}

- (void)testValidateRunsValidationIfRuleAllowsNilAndValueIsNotNil
{
	REDValidationRule *rule = [REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}];
	rule.allowsNil = YES;
	
	id componentMock = [OCMockObject niceMockForProtocol:@protocol(REDValidatableComponent)];
	[[[componentMock stub] andReturn:[NSObject new]] validatedValue];
	
	XCTAssertEqual([rule validate:componentMock], REDValidationResultValid, @"Validation should have run and passed");
}

- (void)testValidateReturnsOptionalValidIfNetworkRuleAllowsNilAndValueIsNil
{
	REDNetworkValidationRule *rule = [REDNetworkValidationRule ruleWithBlock:^NSURLSessionTask *(id value, REDNetworkValidationRuleResultBlock completion) {
		NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:@"http://localhost"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
			completion(YES, nil);
		}];
		[task resume];
		return task;
	}];
	rule.allowsNil = YES;
	
	id componentMock = [OCMockObject niceMockForProtocol:@protocol(REDValidatableComponent)];
	[[[componentMock stub] andReturn:nil] validatedValue];
	
	XCTAssertEqual([rule validate:componentMock], REDValidationResultOptionalValid, @"Validation should not have run since validated value is nil and rule allows nil");
}

- (void)testValidateNotifiesDelegateIfNetworkRuleAllowsNilAndValueIsNil
{
	REDNetworkValidationRule *rule = [REDNetworkValidationRule ruleWithBlock:^NSURLSessionTask *(id value, REDNetworkValidationRuleResultBlock completion) {
		NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:@"http://localhost"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
			completion(YES, nil);
		}];
		[task resume];
		return task;
	}];
	rule.allowsNil = YES;
	
	id componentMock = [OCMockObject niceMockForProtocol:@protocol(REDValidatableComponent)];
	[[[componentMock stub] andReturn:nil] validatedValue];
	
	id delegateMock = [OCMockObject niceMockForProtocol:@protocol(REDNetworkValidationRuleDelegate)];
	rule.delegate = delegateMock;
	[[delegateMock expect] validationRule:rule completedNetworkValidationOfComponent:componentMock withResult:REDValidationResultOptionalValid error:nil];
	
	[rule validate:componentMock];
	
	[delegateMock verify];
}

- (void)testValidateRunsValidationIfNetworkRuleAllowsNilAndValueIsNotNil
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
	rule.allowsNil = YES;
	
	id componentMock = [OCMockObject niceMockForProtocol:@protocol(REDValidatableComponent)];
	[[[componentMock stub] andReturn:[NSObject new]] validatedValue];
	
	id delegateMock = [OCMockObject niceMockForProtocol:@protocol(REDNetworkValidationRuleDelegate)];
	rule.delegate = delegateMock;
	[[delegateMock expect] validationRule:rule completedNetworkValidationOfComponent:componentMock withResult:REDValidationResultValid error:nil];
	
	[rule validate:componentMock];
	
	[self waitForExpectationsWithTimeout:5.0 handler:nil];
	[delegateMock verify];
}

@end
