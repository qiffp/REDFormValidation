//
//  REDValidator.m
//  REDFormValidation
//
//  Created by Sam Dye on 2016-03-04.
//  Copyright © 2016 Sam Dye. All rights reserved.
//

#import "REDValidator.h"
#import "REDValidationRule.h"

@interface REDValidator () <REDValidationComponentDelegate>
@end

@implementation REDValidator {
	__weak UIView *_view;
	NSMutableArray<REDValidationComponent *> *_validationComponents;
}

- (instancetype)initWithView:(UIView *)view
{
	self = [super init];
	if (self) {
		_shouldValidate = YES;
		
		_view = view;
		_validationComponents = [NSMutableArray array];
	}
	return self;
}

- (void)setRule:(id<REDValidationRuleProtocol>)rule forComponentWithTag:(NSInteger)tag validateOn:(REDValidationEvent)event;
{
	REDValidationComponent *validationComponent = [[REDValidationComponent alloc] initWithUIComponent:[_view viewWithTag:tag] validateOn:event];
	validationComponent.rule = rule;
	validationComponent.delegate = self;
	[_validationComponents addObject:validationComponent];
}

- (REDValidationComponent *)validationComponentWithTag:(NSInteger)tag
{
	NSUInteger index = [_validationComponents indexOfObjectPassingTest:^BOOL(REDValidationComponent *obj, NSUInteger idx, BOOL *stop) {
		return obj.tag == tag;
	}];
	return index != NSNotFound ? _validationComponents[index] : nil;
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

#pragma mark - REDValidationComponentDelegate

- (void)validationComponent:(REDValidationComponent *)validationComponent willValidateUIComponent:(UIView *)uiComponent
{
	if ([_delegate respondsToSelector:@selector(validator:willValidateComponent:)]) {
		[_delegate validator:self willValidateComponent:uiComponent];
	}
}

- (void)validationComponent:(REDValidationComponent *)validationComponent didValidateUIComponent:(UIView *)uiComponent result:(BOOL)result
{
	[self validate];
	
	if ([_delegate respondsToSelector:@selector(validator:didValidateComponent:result:)]) {
		[_delegate validator:self didValidateComponent:uiComponent result:result];
	}
}

@end
