//
//  REDValidator.m
//  REDFormValidation
//
//  Created by Sam Dye on 2016-03-04.
//  Copyright © 2016 Sam Dye. All rights reserved.
//

#import "REDValidator.h"
#import "REDValidationRule.h"

@interface REDValidator () <REDValidatedComponentDelegate>
@end

@implementation REDValidator {
	__weak UIView *_view;
	NSMutableArray<REDValidatedComponent *> *_validatedComponents;
}

- (instancetype)initWithView:(UIView *)view
{
	self = [super init];
	if (self) {
		_shouldValidate = YES;
		
		_view = view;
		_validatedComponents = [NSMutableArray array];
	}
	return self;
}

- (void)setRule:(id<REDValidationRuleProtocol>)rule forComponentWithTag:(NSInteger)tag validateOn:(REDValidationEvent)event;
{
	REDValidatedComponent *validatedComponent = [[REDValidatedComponent alloc] initWithUIComponent:[_view viewWithTag:tag] validateOn:event];
	validatedComponent.rule = rule;
	validatedComponent.delegate = self;
	[_validatedComponents addObject:validatedComponent];
}

- (REDValidatedComponent *)validatedComponentWithTag:(NSInteger)tag
{
	NSUInteger index = [_validatedComponents indexOfObjectPassingTest:^BOOL(REDValidatedComponent *obj, NSUInteger idx, BOOL *stop) {
		return obj.tag == tag;
	}];
	return index != NSNotFound ? _validatedComponents[index] : nil;
}

- (BOOL)validate
{
	BOOL result = YES;
	if (_shouldValidate) {
		result = _validationBlock ? _validationBlock(self) : NO;
		
		if ([_delegate respondsToSelector:@selector(validator:didValidateFormWithResult:)]) {
			[_delegate validator:self didValidateFormWithResult:result];
		}
	}
	
	return result;
}

#pragma mark - REDValidatedComponentDelegate

- (void)validatedComponent:(REDValidatedComponent *)validatedComponent willValidateUIComponent:(UIControl *)uiComponent
{
	if ([_delegate respondsToSelector:@selector(validator:willValidateComponent:)]) {
		[_delegate validator:self willValidateComponent:uiComponent];
	}
}

- (void)validatedComponent:(REDValidatedComponent *)validatedComponent didValidateUIComponent:(UIControl *)uiComponent result:(BOOL)result
{
	[self validate];
	
	if ([_delegate respondsToSelector:@selector(validator:didValidateComponent:result:)]) {
		[_delegate validator:self didValidateComponent:uiComponent result:result];
	}
}

@end
