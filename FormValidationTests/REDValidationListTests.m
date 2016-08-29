//
//  REDValidationListTests.m
//  REDFormValidation
//
//  Created by Sam Dye on 2016-08-22.
//  Copyright © 2016 Sam Dye. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "REDValidationList.h"
#import "REDValidationComponent.h"

@interface REDValidationListTests : XCTestCase
@end

@implementation REDValidationListTests {
	UITextField *_textField1;
	UITextField *_textField2;
	UITextField *_textField3;
	UITextField *_textField4;
}

- (void)setUp
{
	[super setUp];
	
	_textField1 = [UITextField new];
	_textField2 = [UITextField new];
	_textField3 = [UITextField new];
	_textField4 = [UITextField new];
}

- (void)tearDown
{
	_textField1 = nil;
	_textField2 = nil;
	_textField3 = nil;
	_textField4 = nil;
	
	[super tearDown];
}

#pragma mark - Helpers

#define returnYES [REDValidationRule ruleWithBlock:^BOOL(id value) { return YES; }]
#define returnNO [REDValidationRule ruleWithBlock:^BOOL(id value) { return NO; }]

- (REDValidationComponent *)componentWithUIComponent:(id<REDValidatableComponent>)uiComponent rule:(id<REDValidationRule>)rule
{
	REDValidationComponent *component = [[REDValidationComponent alloc] initWithValidationEvent:REDValidationEventAll rule:rule];
	component.uiComponent = uiComponent;
	return component;
}

#pragma mark - validateComponents:revalidate:

- (void)testEvaluateSimpleANDSuccess
{
	NSDictionary *components = @{
								 @1 : [self componentWithUIComponent:_textField1 rule:returnYES],
								 @2 : [self componentWithUIComponent:_textField2 rule:returnNO],
								 @3 : [self componentWithUIComponent:_textField3 rule:returnYES],
								 @4 : [self componentWithUIComponent:_textField4 rule:returnNO]
								 };
	
	REDValidationList *list = [REDValidationList and:@[
													   [REDValidationList or:@[@1, @2]],
													   [REDValidationList or:@[@3, @4]]
													   ]];
	
	XCTAssertTrue([list validateComponents:components revalidate:YES], @"Validation should succeed");
}

- (void)testEvaluateSimpleANDFailure
{
	NSDictionary *components = @{
								 @1 : [self componentWithUIComponent:_textField1 rule:returnNO], // changed to cause failure
								 @2 : [self componentWithUIComponent:_textField2 rule:returnNO],
								 @3 : [self componentWithUIComponent:_textField3 rule:returnYES],
								 @4 : [self componentWithUIComponent:_textField4 rule:returnNO]
								 };
	
	REDValidationList *list = [REDValidationList and:@[
													   [REDValidationList or:@[@1, @2]],
													   [REDValidationList or:@[@3, @4]]
													   ]];
	
	XCTAssertFalse([list validateComponents:components revalidate:YES], @"Validation should fail");
}

- (void)testEvaluateSimpleORSuccess
{
	NSDictionary *components = @{
								 @1 : [self componentWithUIComponent:_textField1 rule:returnYES],
								 @2 : [self componentWithUIComponent:_textField2 rule:returnYES],
								 @3 : [self componentWithUIComponent:_textField3 rule:returnNO],
								 @4 : [self componentWithUIComponent:_textField4 rule:returnNO]
								 };
	
	REDValidationList *list = [REDValidationList or:@[
													   [REDValidationList and:@[@1, @2]],
													   [REDValidationList and:@[@3, @4]]
													   ]];
	
	XCTAssertTrue([list validateComponents:components revalidate:YES], @"Validation should succeed");
}

- (void)testEvaluateSimpleORFailure
{
	NSDictionary *components = @{
								 @1 : [self componentWithUIComponent:_textField1 rule:returnNO], // changed to cause failure
								 @2 : [self componentWithUIComponent:_textField2 rule:returnNO], // changed to cause failure
								 @3 : [self componentWithUIComponent:_textField3 rule:returnNO],
								 @4 : [self componentWithUIComponent:_textField4 rule:returnNO]
								 };
	
	REDValidationList *list = [REDValidationList or:@[
													   [REDValidationList or:@[@1, @2]],
													   [REDValidationList or:@[@3, @4]]
													   ]];
	
	XCTAssertFalse([list validateComponents:components revalidate:YES], @"Validation should fail");
}

- (void)testEvaluateComplexSuccess
{
	UITextField *textField5 = [UITextField new];
	UITextField *textField6 = [UITextField new];
	UITextField *textField7 = [UITextField new];
	UITextField *textField8 = [UITextField new];
	UITextField *textField9 = [UITextField new];
	UITextField *textField10 = [UITextField new];
	UITextField *textField11 = [UITextField new];
	UITextField *textField12 = [UITextField new];
	
	NSDictionary *components = @{
								 @1 : [self componentWithUIComponent:_textField1 rule:returnYES],
								 @2 : [self componentWithUIComponent:_textField2 rule:returnNO],
								 @3 : [self componentWithUIComponent:_textField3 rule:returnYES],
								 @4 : [self componentWithUIComponent:_textField4 rule:returnNO],
								 @5 : [self componentWithUIComponent:textField5 rule:returnYES],
								 @6 : [self componentWithUIComponent:textField6 rule:returnNO],
								 @7 : [self componentWithUIComponent:textField7 rule:returnYES],
								 @8 : [self componentWithUIComponent:textField8 rule:returnNO],
								 @9 : [self componentWithUIComponent:textField9 rule:returnYES],
								 @10 : [self componentWithUIComponent:textField10 rule:returnYES],
								 @11 : [self componentWithUIComponent:textField11 rule:returnYES],
								 @12 : [self componentWithUIComponent:textField12 rule:returnYES]
								 };
	
	REDValidationList *list = [REDValidationList and:@[
													   [REDValidationList and:@[
																				[REDValidationList or:@[@1, @2]],
																				[REDValidationList or:@[@3, @4]]
																				]],
													   [REDValidationList and:@[
																				[REDValidationList or:@[@5, @6]],
																				[REDValidationList or:@[@7, @8]]
																				]],
													   [REDValidationList or:@[
																			   [REDValidationList and:@[@9, @10]],
																			   [REDValidationList and:@[@11, @12]]
																			   ]]
													   ]];
	
	XCTAssertTrue([list validateComponents:components revalidate:YES], @"Validation should succeed");
}

- (void)testEvaluateComplexFailure
{
	UITextField *textField5 = [UITextField new];
	UITextField *textField6 = [UITextField new];
	UITextField *textField7 = [UITextField new];
	UITextField *textField8 = [UITextField new];
	UITextField *textField9 = [UITextField new];
	UITextField *textField10 = [UITextField new];
	UITextField *textField11 = [UITextField new];
	UITextField *textField12 = [UITextField new];
	
	NSDictionary *components = @{
								 @1 : [self componentWithUIComponent:_textField1 rule:returnNO], // changed to cause failure
								 @2 : [self componentWithUIComponent:_textField2 rule:returnNO],
								 @3 : [self componentWithUIComponent:_textField3 rule:returnYES],
								 @4 : [self componentWithUIComponent:_textField4 rule:returnNO],
								 @5 : [self componentWithUIComponent:textField5 rule:returnYES],
								 @6 : [self componentWithUIComponent:textField6 rule:returnNO],
								 @7 : [self componentWithUIComponent:textField7 rule:returnYES],
								 @8 : [self componentWithUIComponent:textField8 rule:returnNO],
								 @9 : [self componentWithUIComponent:textField9 rule:returnYES],
								 @10 : [self componentWithUIComponent:textField10 rule:returnYES],
								 @11 : [self componentWithUIComponent:textField11 rule:returnYES],
								 @12 : [self componentWithUIComponent:textField12 rule:returnYES]
								 };
	
	REDValidationList *list = [REDValidationList and:@[
													   [REDValidationList and:@[
																				[REDValidationList or:@[@1, @2]],
																				[REDValidationList or:@[@3, @4]]
																				]],
													   [REDValidationList and:@[
																				[REDValidationList or:@[@5, @6]],
																				[REDValidationList or:@[@7, @8]]
																				]],
													   [REDValidationList or:@[
																			   [REDValidationList and:@[@9, @10]],
																			   [REDValidationList and:@[@11, @12]]
																			   ]]
													   ]];
	
	XCTAssertFalse([list validateComponents:components revalidate:YES], @"Validation should fail");
}

@end
