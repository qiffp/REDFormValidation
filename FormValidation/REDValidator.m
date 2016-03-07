//
//  REDValidator.m
//  REDFormValidation
//
//  Created by Sam Dye on 2016-03-04.
//  Copyright © 2016 Sam Dye. All rights reserved.
//

#import "REDValidator.h"
#import "REDValidationRule.h"

static void *REDTableViewVisibleCellsChangedContext = &REDTableViewVisibleCellsChangedContext;

@interface REDValidator () <REDValidationComponentDelegate, UITableViewDelegate>
@end

@implementation REDValidator {
	__weak UIView *_view;
	__weak id<UITableViewDelegate> _tableViewDelegate;
	NSMutableArray<REDValidationComponent *> *_validationComponents;
	NSMutableArray<NSNumber *> *_validatedTags;
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
		
		_validationComponents = [NSMutableArray array];
		_validatedTags = [NSMutableArray array];
	}
	return self;
}

- (void)setRule:(id<REDValidationRuleProtocol>)rule forComponentWithTag:(NSInteger)tag validateOn:(REDValidationEvent)event;
{
	REDValidationComponent *validationComponent = [[REDValidationComponent alloc] initWithUIComponent:[_view viewWithTag:tag] validateOn:event];
	validationComponent.rule = rule;
	validationComponent.delegate = self;
	[_validationComponents addObject:validationComponent];
	[_validatedTags addObject:@(tag)];
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
	[_validatedTags enumerateObjectsUsingBlock:^(NSNumber *obj, NSUInteger idx, BOOL *stop) {
		UIView *view = [cell viewWithTag:[obj integerValue]];
		if (view) {
			_validationComponents[idx].uiComponent = view;
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
