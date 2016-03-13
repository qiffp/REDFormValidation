//
//  REDValidationComponentTests.m
//  REDFormValidation
//
//  Created by Sam Dye on 2016-03-12.
//  Copyright © 2016 Sam Dye. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "REDValidationComponent.h"

@interface TestValidationComponentDelegate : NSObject <REDValidationComponentDelegate>
@property (nonatomic, assign) BOOL result;
@end

@implementation TestValidationComponentDelegate

- (void)validationComponent:(REDValidationComponent *)validationComponent willValidateUIComponent:(UIView *)uiComponent
{
	
}

- (void)validationComponent:(REDValidationComponent *)validationComponent didValidateUIComponent:(UIView *)uiComponent result:(BOOL)result
{
	_result = result;
}

@end

@interface REDValidationComponentTests : XCTestCase
@end

@implementation REDValidationComponentTests {
	REDValidationComponent *_component;
	TestValidationComponentDelegate *_delegate;
}

- (void)setUp
{
    [super setUp];
	_delegate = [TestValidationComponentDelegate new];
	
	UITextField *textField = [[UITextField alloc] init];
	_component = [[REDValidationComponent alloc] initWithUIComponent:textField validateOn:REDValidationEventAll];
	_component.delegate = _delegate;
	_component.rule = [REDValidationRule ruleWithBlock:^BOOL(UIView *component) {
		return [component isKindOfClass:[UITextField class]];
	}];
}

- (void)tearDown
{
	_component = nil;
    [super tearDown];
}

- (void)testValidPerformsValidationIfNotAlreadyValidated
{
	XCTAssertFalse(_delegate.result, @"Result should not be set before validation");
	XCTAssertTrue(_component.valid, @"Component should be valid");
	XCTAssertTrue(_delegate.result, @"Result should be set since validation has run");
}

- (void)testValidReturnsPreviousValidationResultIfAlreadyValidated
{
	[_component setValue:@YES forKey:@"_validated"];
	
	[_component setValue:@YES forKey:@"_valid"];
	XCTAssertTrue(_component.valid, @"Component should be valid");
	
	[_component setValue:@NO forKey:@"_valid"];
	XCTAssertFalse(_component.valid, @"Component should not be valid");
}

- (void)testValidIsFalseWithNoUIComponent
{
	XCTAssertTrue(_component.valid, @"");
	_component.uiComponent = nil;
	
	[_component setValue:@NO forKey:@"_validated"];
	XCTAssertFalse(_component.valid, @"");
}

@end
