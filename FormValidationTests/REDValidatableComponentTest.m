//
//  REDValidatableComponentTest.m
//  REDFormValidation
//
//  Created by Sam Dye on 2016-06-14.
//  Copyright © 2016 Sam Dye. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "REDValidatableComponent.h"

@interface REDValidatableComponentTest : XCTestCase
@end

@implementation REDValidatableComponentTest

- (void)testUISliderDefaultValue
{
	UISlider *slider = [UISlider new];
	XCTAssertEqualObjects([slider validatedValue], [slider defaultValue]);
}

- (void)testUIStepperDefaultValue
{
	UIStepper *stepper = [UIStepper new];
	XCTAssertEqualObjects([stepper validatedValue], [stepper defaultValue]);
}

- (void)testUITextFieldDefaultValue
{
	UITextField *textField = [UITextField new];
	XCTAssertEqualObjects([textField validatedValue], [textField defaultValue]);
}

- (void)testUITextViewDefaultValue
{
	UITextView *textView = [UITextView new];
	XCTAssertEqualObjects([textView validatedValue], [textView defaultValue]);
}

@end
