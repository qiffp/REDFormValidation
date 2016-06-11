//
//  REDValidatableComponent.m
//  REDFormValidation
//
//  Created by Sam Dye on 2016-06-10.
//  Copyright © 2016 Sam Dye. All rights reserved.
//

#import "REDValidatableComponent.h"

@implementation UIDatePicker (REDValidatableComponent)

- (id)validatedValue
{
	return self.date;
}

@end

@implementation UISegmentedControl (REDValidatableComponent)

- (id)validatedValue
{
	return @(self.selectedSegmentIndex);
}

@end

@implementation UISlider (REDValidatableComponent)

- (id)validatedValue
{
	return [[NSDecimalNumber alloc] initWithFloat:self.value];
}

@end

@implementation UIStepper (REDValidatableComponent)

- (id)validatedValue
{
	return [[NSDecimalNumber alloc] initWithDouble:self.value];
}

@end

@implementation UISwitch (REDValidatableComponent)

- (id)validatedValue
{
	return @(self.on);
}

@end

@implementation UITextField (REDValidatableComponent)

- (id)validatedValue
{
	return self.text;
}

@end

@implementation UITextView (REDValidatableComponent)

- (id)validatedValue
{
	return self.text;
}

@end
