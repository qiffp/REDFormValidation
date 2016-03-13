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

@interface REDValidationComponentTests : XCTestCase
@end

@implementation REDValidationComponentTests {
	REDValidationComponent *_component;
	id _delegate;
}

- (void)setUp
{
    [super setUp];
	_delegate = [OCMockObject niceMockForProtocol:@protocol(REDValidationComponentDelegate)];
	
	UITextField *textField = [[UITextField alloc] init];
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
	[_component setValue:@YES forKey:@"_validated"];
	
	[_component setValue:@YES forKey:@"_valid"];
	XCTAssertTrue(_component.valid, @"Component should be valid");
	
	[_component setValue:@NO forKey:@"_valid"];
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

@end
