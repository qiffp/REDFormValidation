//
//  REDValidationRule.m
//  REDFormValidation
//
//  Created by Sam Dye on 2016-03-04.
//  Copyright © 2016 Sam Dye. All rights reserved.
//

#import "REDValidationRule.h"
#import "REDValidatableComponent.h"

@interface REDValidationRule ()
@property (nonatomic, copy) REDValidationRuleBlock block;
@end

@implementation REDValidationRule

@synthesize allowDefault = _allowDefault;

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

- (REDValidationResult)validate:(NSObject<REDValidatableComponent> *)component
{
	id value = [component validatedValue];
	
	if (_allowDefault && [value isEqual:[component defaultValue]]) {
		return REDValidationResultDefaultValid;
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

@synthesize allowDefault = _allowDefault;

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

- (REDValidationResult)validate:(NSObject<REDValidatableComponent> *)component
{
	[self cancel];
	
	id value = [component validatedValue];
	
	if (_allowDefault && [value isEqual:[component defaultValue]]) {
		REDValidationResult result = REDValidationResultDefaultValid;
		[_delegate validationRule:self completedNetworkValidationOfComponent:component withResult:result error:nil];
		return result;
	}
	
	return [self validateComponent:component value:value];
}

- (REDValidationResult)validateValue:(id)value
{
	return [self validateComponent:nil value:value];
}

- (REDValidationResult)validateComponent:(NSObject<REDValidatableComponent> *)component value:(id)value
{
	if (_block) {
		__weak typeof(self) weakSelf = self;
		_task = _block(value, ^void(BOOL result, NSError *error) {
			__strong typeof(weakSelf) strongSelf = weakSelf;
			REDValidationResult validationResult = result ? REDValidationResultValid : REDValidationResultInvalid;
			[strongSelf.delegate validationRule:strongSelf completedNetworkValidationOfComponent:component withResult:validationResult error:error];
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
