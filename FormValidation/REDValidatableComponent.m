//
//  REDValidatableComponent.m
//  REDFormValidation
//
//  Created by Sam Dye on 2016-06-10.
//  Copyright © 2016 Sam Dye. All rights reserved.
//

#import "REDValidatableComponent.h"

float const kUISliderDefaultValue = 0.0f;
double const kUIStepperDefaultValue = 0.0;
NSString *const kUITextFieldDefaultValue = @"";
NSString *const kUITextViewDefaultValue = @"";

@implementation UISlider (REDValidatableComponent)

- (id)validatedValue
{
	return [[NSDecimalNumber alloc] initWithFloat:self.value];
}

- (id)defaultValue
{
	static NSDecimalNumber *value = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		value = [[NSDecimalNumber alloc] initWithFloat:kUISliderDefaultValue];
	});
	return value;
}

@end

@implementation UIStepper (REDValidatableComponent)

- (id)validatedValue
{
	return [[NSDecimalNumber alloc] initWithDouble:self.value];
}

- (id)defaultValue
{
	static NSDecimalNumber *value = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		value = [[NSDecimalNumber alloc] initWithDouble:kUIStepperDefaultValue];
	});
	return value;
}

@end

@implementation UITextField (REDValidatableComponent)

- (id)validatedValue
{
	return self.text;
}

- (id)defaultValue
{
	return kUITextFieldDefaultValue;
}

@end

@implementation UITextView (REDValidatableComponent)

- (id)validatedValue
{
	return self.text;
}

- (id)defaultValue
{
	return kUITextViewDefaultValue;
}

@end
