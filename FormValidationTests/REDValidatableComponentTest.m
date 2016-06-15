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
	XCTAssertEqualObjects([slider validatedValue], [slider defaultValue], @"UISlider default value should be correct");
}

- (void)testUIStepperDefaultValue
{
	UIStepper *stepper = [UIStepper new];
	XCTAssertEqualObjects([stepper validatedValue], [stepper defaultValue], @"UIStepper default value should be correct");
}

- (void)testUITextFieldDefaultValue
{
	UITextField *textField = [UITextField new];
	XCTAssertEqualObjects([textField validatedValue], [textField defaultValue], @"UITextField default value should be correct");
}

- (void)testUITextViewDefaultValue
{
	UITextView *textView = [UITextView new];
	XCTAssertEqualObjects([textView validatedValue], [textView defaultValue], @"UITextView default value should be correct");
}

@end
