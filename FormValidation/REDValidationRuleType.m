//
//  REDValidationRuleType.m
//  REDFormValidation
//
//  Created by Sam Dye on 2016-03-04.
//  Copyright © 2016 Sam Dye. All rights reserved.
//

#import "REDValidationRuleType.h"
#import "REDValidatableComponent.h"

@interface REDValidationRule ()
@property (nonatomic, copy) REDValidationRuleBlock block;
@end

@implementation REDValidationRule

+ (instancetype)ruleWithBlock:(REDValidationRuleBlock)block
{
	return [[self alloc] initWithBlock:block];
}

- (instancetype)initWithBlock:(REDValidationRuleBlock)block
{
	self = [super init];
	if (self) {
		_block = [block copy];
	}
	return self;
}

- (REDValidationResult)validate:(id<REDValidatableComponent>)uiComponent allowDefault:(BOOL)allowDefault
{
	id value = [uiComponent validatedValue];
	
	if ([value isEqual:[uiComponent defaultValue]]) {
		return allowDefault ? REDValidationResultDefaultValid : REDValidationResultUnvalidated;
	}
	
	return [self validateValue:value];
}

- (REDValidationResult)validateValue:(id)value
{
	if (_block) {
		return _block(value) ? REDValidationResultValid : REDValidationResultInvalid;
	} else {
		return REDValidationResultInvalid;
	}
}

- (void)cancel
{
}

@end

@interface REDNetworkValidationRule ()
@property (nonatomic, copy) REDNetworkValidationRuleBlock block;
@end

@implementation REDNetworkValidationRule {
	__weak NSURLSessionTask *_task;
}

+ (instancetype)ruleWithBlock:(REDNetworkValidationRuleBlock)block
{
	return [[self alloc] initWithBlock:block];
}

- (instancetype)initWithBlock:(REDNetworkValidationRuleBlock)block
{
	self = [super init];
	if (self) {
		_block = [block copy];
	}
	return self;
}

- (REDValidationResult)validate:(id<REDValidatableComponent>)uiComponent allowDefault:(BOOL)allowDefault
{
	[self cancel];
	
	id value = [uiComponent validatedValue];
	
	if (allowDefault && [value isEqual:[uiComponent defaultValue]]) {
		REDValidationResult result = REDValidationResultDefaultValid;
		[_delegate validationRule:self completedNetworkValidationOfUIComponent:uiComponent withResult:result error:nil];
		return result;
	}
	
	return [self validateUIComponent:uiComponent value:value];
}

- (REDValidationResult)validateValue:(id)value
{
	return [self validateUIComponent:nil value:value];
}

- (REDValidationResult)validateUIComponent:(NSObject<REDValidatableComponent> *)component value:(id)value
{
	if (_block) {
		__weak typeof(self) weakSelf = self;
		_task = _block(value, ^void(BOOL result, NSError *error) {
			__strong typeof(weakSelf) strongSelf = weakSelf;
			REDValidationResult validationResult = result ? REDValidationResultValid : REDValidationResultInvalid;
			[strongSelf.delegate validationRule:strongSelf completedNetworkValidationOfUIComponent:component withResult:validationResult error:error];
		});
		
		return REDValidationResultPending;
	} else {
		return REDValidationResultInvalid;
	}
}

- (void)cancel
{
	[_task cancel];
	_task = nil;
}

@end
