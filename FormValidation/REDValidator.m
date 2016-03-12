//
//  REDValidator.m
//  REDFormValidation
//
//  Created by Sam Dye on 2016-03-04.
//  Copyright © 2016 Sam Dye. All rights reserved.
//

#import "REDValidator.h"
#import "REDValidationRule.h"
#import "REDValidationComponent.h"

static void *REDTableViewVisibleCellsChangedContext = &REDTableViewVisibleCellsChangedContext;

@interface REDValidator () <REDValidationComponentDelegate, UITableViewDelegate>
@end

@implementation REDValidator {
	__weak UIView *_view;
	__weak id<UITableViewDelegate> _tableViewDelegate;
	
	NSMutableDictionary<NSNumber *, REDValidationComponent *> *_validationComponents;
	
	REDTableViewValidationBlock _validationBlock;
	BOOL _evaluatingBlock;
}

- (instancetype)initWithView:(UIView *)view
{
	self = [super init];
	if (self) {
		_shouldValidate = YES;
		
		_view = view;
		if ([_view isKindOfClass:[UITableView class]]) {
			_tableViewDelegate = ((UITableView *)_view).delegate;
			((UITableView *)_view).delegate = self;
		}
		
		_validationComponents = [NSMutableDictionary dictionary];
	}
	return self;
}

- (void)setValidationBlock:(REDTableViewValidationBlock)validationBlock
{
	_validationBlock = [validationBlock copy];
	[self evaluateValidationBlock];
}

- (void)setRule:(id<REDValidationRuleProtocol>)rule forComponentWithTag:(NSInteger)tag validateOn:(REDValidationEvent)event;
{
	REDValidationComponent *validationComponent = [[REDValidationComponent alloc] initWithUIComponent:[_view viewWithTag:tag] validateOn:event];
	validationComponent.rule = rule;
	validationComponent.delegate = self;
	_validationComponents[@(tag)] = validationComponent;
	[self evaluateValidationBlock];
}

- (BOOL)componentWithTagIsValid:(NSInteger)tag
{
	if (_evaluatingBlock) {
		_validationComponents[@(tag)].validatedInValidatorBlock = YES;
		return NO;
	} else {
		return _validationComponents[@(tag)].valid;
	}
}

- (BOOL)validate
{
	BOOL result = YES;
	if (_shouldValidate) {
		if (_validationBlock) {
			result = _validationBlock(self);
			
			for (REDValidationComponent *component in _validationComponents.allValues) {
				if (component.validatedInValidatorBlock == NO) {
					result &= component.valid;
				}
			}
		} else {
			for (REDValidationComponent *component in _validationComponents.allValues) {
				result &= component.valid;
			}
		}
		
		if ([_delegate respondsToSelector:@selector(validator:didValidateFormWithResult:)]) {
			[_delegate validator:self didValidateFormWithResult:result];
		}
	}
	
	return result;
}

#pragma mark - Helpers

- (void)evaluateValidationBlock
{
	if (_validationBlock) {
		for (REDValidationComponent *validationComponent in _validationComponents.allValues) {
			validationComponent.validatedInValidatorBlock = NO;
		}
		_evaluatingBlock = YES;
		_validationBlock(self);
		_evaluatingBlock = NO;
	}
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

#pragma mark - Delegate Funny Business

- (BOOL)respondsToSelector:(SEL)aSelector
{
	return [super respondsToSelector:aSelector] || [_tableViewDelegate respondsToSelector:aSelector];
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
	if ([_tableViewDelegate respondsToSelector:aSelector]) {
		return _tableViewDelegate;
	}
	
	return [super forwardingTargetForSelector:aSelector];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
	[_validationComponents.allKeys enumerateObjectsUsingBlock:^(NSNumber *tag, NSUInteger idx, BOOL *stop) {
		UIView *view = [cell viewWithTag:[tag integerValue]];
		if (view) {
			_validationComponents[tag].uiComponent = view;
			*stop = YES;
		}
	}];
	
	if ([_tableViewDelegate respondsToSelector:@selector(tableView:willDisplayCell:forRowAtIndexPath:)]) {
		[_tableViewDelegate tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
	}
}

// don't think this is necessary since _uiComponent is weak

//- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath*)indexPath
//{
//	[_validatedTags enumerateObjectsUsingBlock:^(NSNumber *obj, NSUInteger idx, BOOL *stop) {
//		UIView *view = [cell viewWithTag:[obj integerValue]];
//		if (view) {
//			_validationComponents[idx].uiComponent = nil;
//			*stop = YES;
//		}
//	}];
//}

@end
