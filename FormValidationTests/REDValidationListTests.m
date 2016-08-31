//
//  REDValidationTreeTests.m
//  REDFormValidation
//
//  Created by Sam Dye on 2016-08-22.
//  Copyright © 2016 Sam Dye. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "REDValidationTree.h"
#import "REDValidationTree+Private.h"
#import "REDValidationComponent.h"

@interface REDValidationTreeTests : XCTestCase
@end

@implementation REDValidationTreeTests {
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

- (REDValidationComponent *)componentWithUIComponent:(id<REDValidatableComponent>)uiComponent rule:(id<REDValidationRuleType>)rule
{
	REDValidationComponent *component = [[REDValidationComponent alloc] initWithInitialValue:nil validationEvent:REDValidationEventAll rule:rule];
	component.uiComponent = uiComponent;
	return component;
}

#pragma mark - validateComponents:revalidate:

- (void)testEvaluateANDIdentifiersSuccess
{
	NSDictionary *components = @{
								 @1 : [self componentWithUIComponent:_textField1 rule:returnYES],
								 @2 : [self componentWithUIComponent:_textField2 rule:returnYES],
								 @3 : [self componentWithUIComponent:_textField3 rule:returnYES],
								 };
	
	REDValidationTree *tree = [[REDValidationTree single:@1] and:@[@2, @3]];
	
	XCTAssertTrue([tree validateComponents:components revalidate:YES], @"Validation should succeed");
}

- (void)testEvaluateANDIdentifiersFailure
{
	NSDictionary *components = @{
								 @1 : [self componentWithUIComponent:_textField1 rule:returnNO], // changed to cause failure
								 @2 : [self componentWithUIComponent:_textField2 rule:returnYES],
								 @3 : [self componentWithUIComponent:_textField3 rule:returnYES],
								 };
	
	REDValidationTree *tree = [[REDValidationTree single:@1] and:@[@2, @3]];
	
	XCTAssertFalse([tree validateComponents:components revalidate:YES], @"Validation should fail");
}

- (void)testEvaluateORIdentifiersSuccess
{
	NSDictionary *components = @{
								 @1 : [self componentWithUIComponent:_textField1 rule:returnNO],
								 @2 : [self componentWithUIComponent:_textField2 rule:returnNO],
								 @3 : [self componentWithUIComponent:_textField3 rule:returnYES],
								 };
	
	REDValidationTree *tree = [[REDValidationTree single:@1] or:@[@2, @3]];
	
	XCTAssertTrue([tree validateComponents:components revalidate:YES], @"Validation should succeed");
}

- (void)testEvaluateORIdentifiersFailure
{
	NSDictionary *components = @{
								 @1 : [self componentWithUIComponent:_textField1 rule:returnNO],
								 @2 : [self componentWithUIComponent:_textField2 rule:returnNO],
								 @3 : [self componentWithUIComponent:_textField3 rule:returnNO], // changed to cause failure
								 };
	
	REDValidationTree *tree = [[REDValidationTree single:@1] or:@[@2, @3]];
	
	XCTAssertFalse([tree validateComponents:components revalidate:YES], @"Validation should fail");
}

- (void)testEvaluateSimpleANDTreesSuccess
{
	NSDictionary *components = @{
								 @1 : [self componentWithUIComponent:_textField1 rule:returnYES],
								 @2 : [self componentWithUIComponent:_textField2 rule:returnNO],
								 @3 : [self componentWithUIComponent:_textField3 rule:returnYES],
								 @4 : [self componentWithUIComponent:_textField4 rule:returnNO]
								 };
	
	REDValidationTree *tree = [REDValidationTree and:@[
													   [REDValidationTree or:@[@1, @2]],
													   [REDValidationTree or:@[@3, @4]]
													   ]];
	
	XCTAssertTrue([tree validateComponents:components revalidate:YES], @"Validation should succeed");
}

- (void)testEvaluateSimpleANDTreesFailure
{
	NSDictionary *components = @{
								 @1 : [self componentWithUIComponent:_textField1 rule:returnNO], // changed to cause failure
								 @2 : [self componentWithUIComponent:_textField2 rule:returnNO],
								 @3 : [self componentWithUIComponent:_textField3 rule:returnYES],
								 @4 : [self componentWithUIComponent:_textField4 rule:returnNO]
								 };
	
	REDValidationTree *tree = [REDValidationTree and:@[
													   [REDValidationTree or:@[@1, @2]],
													   [REDValidationTree or:@[@3, @4]]
													   ]];
	
	XCTAssertFalse([tree validateComponents:components revalidate:YES], @"Validation should fail");
}

- (void)testEvaluateSimpleORTreesSuccess
{
	NSDictionary *components = @{
								 @1 : [self componentWithUIComponent:_textField1 rule:returnYES],
								 @2 : [self componentWithUIComponent:_textField2 rule:returnYES],
								 @3 : [self componentWithUIComponent:_textField3 rule:returnNO],
								 @4 : [self componentWithUIComponent:_textField4 rule:returnNO]
								 };
	
	REDValidationTree *tree = [REDValidationTree or:@[
													   [REDValidationTree and:@[@1, @2]],
													   [REDValidationTree and:@[@3, @4]]
													   ]];
	
	XCTAssertTrue([tree validateComponents:components revalidate:YES], @"Validation should succeed");
}

- (void)testEvaluateSimpleORTreesFailure
{
	NSDictionary *components = @{
								 @1 : [self componentWithUIComponent:_textField1 rule:returnNO], // changed to cause failure
								 @2 : [self componentWithUIComponent:_textField2 rule:returnNO], // changed to cause failure
								 @3 : [self componentWithUIComponent:_textField3 rule:returnNO],
								 @4 : [self componentWithUIComponent:_textField4 rule:returnNO]
								 };
	
	REDValidationTree *tree = [REDValidationTree or:@[
													   [REDValidationTree or:@[@1, @2]],
													   [REDValidationTree or:@[@3, @4]]
													   ]];
	
	XCTAssertFalse([tree validateComponents:components revalidate:YES], @"Validation should fail");
}

- (void)testEvaluateComplexTreesSuccess
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
	
	REDValidationTree *tree = [REDValidationTree and:@[
													   [REDValidationTree and:@[
																				[REDValidationTree or:@[@1, @2]],
																				[REDValidationTree or:@[@3, @4]]
																				]],
													   [REDValidationTree and:@[
																				[REDValidationTree or:@[@5, @6]],
																				[REDValidationTree or:@[@7, @8]]
																				]],
													   [REDValidationTree or:@[
																			   [REDValidationTree and:@[@9, @10]],
																			   [REDValidationTree and:@[@11, @12]]
																			   ]]
													   ]];
	
	XCTAssertTrue([tree validateComponents:components revalidate:YES], @"Validation should succeed");
}

- (void)testEvaluateComplexTreesFailure
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
	
	REDValidationTree *tree = [REDValidationTree and:@[
													   [REDValidationTree and:@[
																				[REDValidationTree or:@[@1, @2]],
																				[REDValidationTree or:@[@3, @4]]
																				]],
													   [REDValidationTree and:@[
																				[REDValidationTree or:@[@5, @6]],
																				[REDValidationTree or:@[@7, @8]]
																				]],
													   [REDValidationTree or:@[
																			   [REDValidationTree and:@[@9, @10]],
																			   [REDValidationTree and:@[@11, @12]]
																			   ]]
													   ]];
	
	XCTAssertFalse([tree validateComponents:components revalidate:YES], @"Validation should fail");
}

#pragma mark - evaluateComponents:

- (void)testEvaluateComponents
{
	UITextField *textField5 = [UITextField new];
	
	NSDictionary<id, REDValidationComponent *> *components = @{
								 @1 : [self componentWithUIComponent:_textField1 rule:returnYES],
								 @2 : [self componentWithUIComponent:_textField2 rule:returnNO],
								 @3 : [self componentWithUIComponent:_textField3 rule:returnYES],
								 @4 : [self componentWithUIComponent:_textField4 rule:returnNO],
								 @5 : [self componentWithUIComponent:textField5 rule:returnYES]
								 };
	
	REDValidationTree *tree = [REDValidationTree and:@[
														 [REDValidationTree or:@[
																				 [REDValidationTree and:@[@1, @2]],
																				 [REDValidationTree single:@3]
																				 ]],
														 [REDValidationTree single:@4]
														 ]];
	
	[tree evaluateComponents:components];
	
	XCTAssertTrue(components[@1].validatedInValidationTree);
	XCTAssertTrue(components[@2].validatedInValidationTree);
	XCTAssertTrue(components[@3].validatedInValidationTree);
	XCTAssertTrue(components[@4].validatedInValidationTree);
	XCTAssertFalse(components[@5].validatedInValidationTree);
}

@end
