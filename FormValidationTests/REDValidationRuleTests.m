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
	
	id delegate = [OCMockObject niceMockForProtocol:@protocol(REDNetworkValidationRuleDelegate)];
	rule.delegate = delegate;
	
	[[delegate expect] validationRule:rule completedNetworkValidationOfComponent:nil withResult:REDValidationResultValid error:nil];
	XCTAssertEqual([rule validate:nil], REDValidationResultPending, @"Validation should be pending until completion is called");
	
	[self waitForExpectationsWithTimeout:5.0 handler:nil];
	[delegate verify];
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
	
	id delegate = [OCMockObject niceMockForProtocol:@protocol(REDNetworkValidationRuleDelegate)];
	rule.delegate = delegate;
	
	[[delegate expect] validationRule:rule completedNetworkValidationOfComponent:nil withResult:REDValidationResultInvalid error:nil];
	XCTAssertEqual([rule validate:nil], REDValidationResultPending, @"Validation should be pending until completion is called");
	
	[self waitForExpectationsWithTimeout:5.0 handler:nil];
	[delegate verify];
}

- (void)testNetworkRuleFailsValidationWithoutABlock
{
	REDNetworkValidationRule *rule = [REDNetworkValidationRule ruleWithBlock:nil];
	XCTAssertEqual([rule validate:nil], REDValidationResultInvalid, @"Validation should fail");
}

@end
