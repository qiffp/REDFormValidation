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
	UITextField *_unvalidatedTextField;
	REDValidationResult _allResultsMask;
}

- (void)setUp
{
	[super setUp];
	
	_textField1 = [UITextField new];
	_textField1.text = @"test";
	_textField2 = [UITextField new];
	_textField2.text = @"test";
	_textField3 = [UITextField new];
	_textField3.text = @"test";
	_textField4 = [UITextField new];
	_textField4.text = @"test";
	_unvalidatedTextField = [UITextField new];
	_allResultsMask = 0b11111;
}

- (void)tearDown
{
	_textField1 = nil;
	_textField2 = nil;
	_textField3 = nil;
	_textField4 = nil;
	_unvalidatedTextField = nil;
	
	[super tearDown];
}

#pragma mark - Helpers

#define returnYES [REDValidationRule ruleWithBlock:^BOOL(id value) { return YES; }]
#define returnNO [REDValidationRule ruleWithBlock:^BOOL(id value) { return NO; }]

- (REDValidationComponent *)componentWithUIComponent:(id<REDValidatableComponent>)uiComponent rule:(id<REDValidationRuleType>)rule
{
	REDValidationComponent *component = [[REDValidationComponent alloc] initWithInitialValue:nil validationEvent:REDValidationEventDefault rule:rule];
	component.uiComponent = uiComponent;
	return component;
}

#pragma mark - validateComponents:revalidate:

- (void)testEvaluateANDIdentifiersSuccess
{
	NSDictionary *components = @{
								 @1 : [self componentWithUIComponent:_textField1 rule:returnYES],
								 @2 : [self componentWithUIComponent:_textField2 rule:returnYES],
								 };
	
	REDValidationTree *tree = [REDValidationTree and:@[@1, @2]];
	
	XCTAssertEqual([tree validateComponents:components revalidate:YES], REDValidationResultValid);
}

- (void)testEvaluateANDIdentifiersFailure
{
	NSDictionary *components = @{
								 @1 : [self componentWithUIComponent:_textField1 rule:returnNO], // changed to cause failure
								 @2 : [self componentWithUIComponent:_textField2 rule:returnYES],
								 };
	
	REDValidationTree *tree = [REDValidationTree and:@[@1, @2]];
	
	XCTAssertEqual([tree validateComponents:components revalidate:YES], REDValidationResultInvalid);
}

- (void)testEvaluateORIdentifiersSuccess
{
	NSDictionary *components = @{
								 @1 : [self componentWithUIComponent:_textField1 rule:returnYES],
								 @2 : [self componentWithUIComponent:_unvalidatedTextField rule:nil],
								 };
	
	REDValidationTree *tree = [REDValidationTree or:@[@1, @2]];
	
	XCTAssertEqual([tree validateComponents:components revalidate:YES], REDValidationResultValid);
}

- (void)testEvaluateORIdentifiersFailure
{
	NSDictionary *components = @{
								 @1 : [self componentWithUIComponent:_textField1 rule:returnNO], // changed to cause failure
								 @2 : [self componentWithUIComponent:_unvalidatedTextField rule:nil],
								 };
	
	REDValidationTree *tree = [REDValidationTree or:@[@1, @2]];
	
	XCTAssertEqual([tree validateComponents:components revalidate:YES], REDValidationResultInvalid);
}

- (void)testEvaluateSimpleANDTreesSuccess
{
	NSDictionary *components = @{
								 @1 : [self componentWithUIComponent:_textField1 rule:returnYES],
								 @2 : [self componentWithUIComponent:_unvalidatedTextField rule:nil],
								 @3 : [self componentWithUIComponent:_textField3 rule:returnYES],
								 @4 : [self componentWithUIComponent:_textField4 rule:returnYES]
								 };
	
	REDValidationTree *tree = [REDValidationTree and:@[
													   [REDValidationTree or:@[@1, @2]],
													   [REDValidationTree or:@[@3, @4]]
													   ]];
	
	XCTAssertEqual([tree validateComponents:components revalidate:YES], REDValidationResultValid);
}

- (void)testEvaluateSimpleANDTreesFailure
{
	NSDictionary *components = @{
								 @1 : [self componentWithUIComponent:_textField1 rule:returnNO], // changed to cause failure
								 @2 : [self componentWithUIComponent:_unvalidatedTextField rule:nil],
								 @3 : [self componentWithUIComponent:_textField3 rule:returnYES],
								 @4 : [self componentWithUIComponent:_textField4 rule:returnYES]
								 };
	
	REDValidationTree *tree = [REDValidationTree and:@[
													   [REDValidationTree or:@[@1, @2]],
													   [REDValidationTree or:@[@3, @4]]
													   ]];
	
	XCTAssertEqual([tree validateComponents:components revalidate:YES], REDValidationResultInvalid);
}

- (void)testEvaluateSimpleORTreesSuccess
{
	NSDictionary *components = @{
								 @1 : [self componentWithUIComponent:_textField1 rule:returnYES],
								 @2 : [self componentWithUIComponent:_textField2 rule:returnYES],
								 @3 : [self componentWithUIComponent:_textField3 rule:returnYES],
								 @4 : [self componentWithUIComponent:_textField4 rule:returnYES]
								 };
	
	REDValidationTree *tree = [REDValidationTree or:@[
													   [REDValidationTree and:@[@1, @2]],
													   [REDValidationTree and:@[@3, @4]]
													   ]];
	
	XCTAssertEqual([tree validateComponents:components revalidate:YES], REDValidationResultValid);
}

- (void)testEvaluateSimpleORTreesFailure
{
	NSDictionary *components = @{
								 @1 : [self componentWithUIComponent:_textField1 rule:returnNO], // changed to cause failure
								 @2 : [self componentWithUIComponent:_textField2 rule:returnYES],
								 @3 : [self componentWithUIComponent:_textField3 rule:returnYES],
								 @4 : [self componentWithUIComponent:_textField4 rule:returnYES]
								 };
	
	REDValidationTree *tree = [REDValidationTree or:@[
													   [REDValidationTree and:@[@1, @2]],
													   [REDValidationTree and:@[@3, @4]]
													   ]];
	
	XCTAssertEqual([tree validateComponents:components revalidate:YES], REDValidationResultInvalid);
}

- (void)testEvaluateComplexTreesSuccess
{
	UITextField *textField5 = [UITextField new];
	textField5.text = @"test";
	UITextField *textField6 = [UITextField new];
	textField6.text = @"test";
	UITextField *textField7 = [UITextField new];
	textField7.text = @"test";
	UITextField *textField8 = [UITextField new];
	textField8.text = @"test";
	UITextField *textField9 = [UITextField new];
	textField9.text = @"test";
	UITextField *textField10 = [UITextField new];
	textField10.text = @"test";
	UITextField *textField11 = [UITextField new];
	textField11.text = @"test";
	UITextField *textField12 = [UITextField new];
	textField12.text = @"test";
	
	NSDictionary *components = @{
								 @1 : [self componentWithUIComponent:_textField1 rule:returnYES],
								 @2 : [self componentWithUIComponent:_unvalidatedTextField rule:nil],
								 @3 : [self componentWithUIComponent:_textField3 rule:returnYES],
								 @4 : [self componentWithUIComponent:_textField4 rule:returnYES],
								 @5 : [self componentWithUIComponent:textField5 rule:returnYES],
								 @6 : [self componentWithUIComponent:textField6 rule:returnYES],
								 @7 : [self componentWithUIComponent:textField7 rule:returnYES],
								 @8 : [self componentWithUIComponent:textField8 rule:returnYES],
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
	
	XCTAssertEqual([tree validateComponents:components revalidate:YES], REDValidationResultValid);
}

- (void)testEvaluateComplexTreesFailure
{
	UITextField *textField5 = [UITextField new];
	textField5.text = @"test";
	UITextField *textField6 = [UITextField new];
	textField6.text = @"test";
	UITextField *textField7 = [UITextField new];
	textField7.text = @"test";
	UITextField *textField8 = [UITextField new];
	textField8.text = @"test";
	UITextField *textField9 = [UITextField new];
	textField9.text = @"test";
	UITextField *textField10 = [UITextField new];
	textField10.text = @"test";
	UITextField *textField11 = [UITextField new];
	textField11.text = @"test";
	UITextField *textField12 = [UITextField new];
	textField12.text = @"test";
	
	NSDictionary *components = @{
								 @1 : [self componentWithUIComponent:_textField1 rule:returnNO], // changed to cause failure
								 @2 : [self componentWithUIComponent:_unvalidatedTextField rule:nil],
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
	
	XCTAssertEqual([tree validateComponents:components revalidate:YES], REDValidationResultInvalid);
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

#pragma mark - resultForMask:operation:

- (void)testResultForMaskEvaluationOrder
{
	XCTAssertEqual([REDValidationTree resultForMask:_allResultsMask operation:REDValidationOperationNone], REDValidationResultInvalid);
	
	_allResultsMask ^= REDValidationResultInvalid;
	XCTAssertEqual([REDValidationTree resultForMask:_allResultsMask operation:REDValidationOperationNone], REDValidationResultPending);
	
	_allResultsMask ^= REDValidationResultPending;
	XCTAssertEqual([REDValidationTree resultForMask:_allResultsMask operation:REDValidationOperationNone], REDValidationResultUnvalidated);
	
	_allResultsMask ^= REDValidationResultUnvalidated;
	XCTAssertEqual([REDValidationTree resultForMask:_allResultsMask operation:REDValidationOperationNone], REDValidationResultValid);
}

- (void)testResultForMaskReturnsUnvalidatedForAllOperationsIfMaskIsEqualToUnvalidated
{
	XCTAssertEqual([REDValidationTree resultForMask:REDValidationResultUnvalidated operation:REDValidationOperationNone], REDValidationResultUnvalidated);
	XCTAssertEqual([REDValidationTree resultForMask:REDValidationResultUnvalidated operation:REDValidationOperationAND], REDValidationResultUnvalidated);
	XCTAssertEqual([REDValidationTree resultForMask:REDValidationResultUnvalidated operation:REDValidationOperationOR], REDValidationResultUnvalidated);
}

- (void)testResultForMaskReturnsUnvalidatedForNoneOperationIfMaskHasUnvalidatedBit
{
	REDValidationResult mask = _allResultsMask ^ REDValidationResultInvalid ^ REDValidationResultPending;
	XCTAssertEqual([REDValidationTree resultForMask:mask operation:REDValidationOperationNone], REDValidationResultUnvalidated);
}

- (void)testResultForMaskReturnsInvalidForANDOperationIfMaskHasUnvalidatedBit
{
	REDValidationResult mask = _allResultsMask ^ REDValidationResultInvalid ^ REDValidationResultPending;
	XCTAssertEqual([REDValidationTree resultForMask:mask operation:REDValidationOperationAND], REDValidationResultInvalid);
}

- (void)testResultForMaskReturnsValidForOROperationIfMaskHasUnvalidatedBit
{
	REDValidationResult mask = _allResultsMask ^ REDValidationResultInvalid ^ REDValidationResultPending;
	XCTAssertEqual([REDValidationTree resultForMask:mask operation:REDValidationOperationOR], REDValidationResultValid);
}

@end
