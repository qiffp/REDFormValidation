//
//  REDValidationRuleTests.m
//  REDFormValidation
//
//  Created by Sam Dye on 2016-03-06.
//  Copyright © 2016 Sam Dye. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "REDValidationRule.h"

@interface TestValidationRuleDelegate : NSObject <REDNetworkValidationRuleDelegate>
@property (nonatomic, assign) REDValidationResult result;
@end

@implementation TestValidationRuleDelegate

- (void)validationRule:(id<REDValidationRuleProtocol>)rule didValidateWithResult:(REDValidationResult)result error:(NSError *)error
{
	_result = result;
}

@end

@interface REDValidationRuleTests : XCTestCase
@end

@implementation REDValidationRuleTests

- (void)testRulePassingValidation
{
	REDValidationRule *rule = [REDValidationRule ruleWithBlock:^BOOL(UIControl *component) {
		return YES;
	}];
	XCTAssertEqual([rule validate:nil], REDValidationResultSuccess, @"Validation should succeed");
}

- (void)testRuleFailingValidation
{
	REDValidationRule *rule = [REDValidationRule ruleWithBlock:^BOOL(UIControl *component) {
		return NO;
	}];
	XCTAssertEqual([rule validate:nil], REDValidationResultFailure, @"Validation should fail");
}

- (void)testRuleFailsValidationWithoutABlock
{
	REDValidationRule *rule = [REDValidationRule ruleWithBlock:nil];
	XCTAssertEqual([rule validate:nil], REDValidationResultFailure, @"Validation should fail");
}

- (void)testNetworkRulePassingValidation
{
	XCTestExpectation *validationExpectation = [self expectationWithDescription:@"validated"];
	REDNetworkValidationRule *rule = [REDNetworkValidationRule ruleWithBlock:^NSURLSessionTask *(UIControl *component, REDNetworkValidationResultBlock completion) {
		NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:@"http://localhost"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
			completion(YES, nil);
			
			[validationExpectation fulfill];
		}];
		[task resume];
		return task;
	}];
	
	TestValidationRuleDelegate *delegate = [TestValidationRuleDelegate new];
	rule.delegate = delegate;
	
	XCTAssertEqual([rule validate:nil], REDValidationResultPending, @"Validation should be pending until completion is called");
	[self waitForExpectationsWithTimeout:5.0 handler:nil];
	XCTAssertEqual(delegate.result, REDValidationResultSuccess, @"Validation should pass");
}

- (void)testNetworkRuleFailingValidation
{
	XCTestExpectation *validationExpectation = [self expectationWithDescription:@"validated"];
	REDNetworkValidationRule *rule = [REDNetworkValidationRule ruleWithBlock:^NSURLSessionTask *(UIControl *component, REDNetworkValidationResultBlock completion) {
		NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:@"http://localhost"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
			completion(NO, nil);
			
			[validationExpectation fulfill];
		}];
		[task resume];
		return task;
	}];
	
	TestValidationRuleDelegate *delegate = [TestValidationRuleDelegate new];
	rule.delegate = delegate;
	
	XCTAssertEqual([rule validate:nil], REDValidationResultPending, @"Validation should be pending until completion is called");
	[self waitForExpectationsWithTimeout:5.0 handler:nil];
	XCTAssertEqual(delegate.result, REDValidationResultFailure, @"Validation should fail");
}

- (void)testNetworkRuleFailsValidationWithoutABlock
{
	REDNetworkValidationRule *rule = [REDNetworkValidationRule ruleWithBlock:nil];
	XCTAssertEqual([rule validate:nil], REDValidationResultFailure, @"Validation should fail");
}

@end
