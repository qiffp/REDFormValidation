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

@synthesize allowsNil = _allowsNil;

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
	
	if (_allowsNil && value == nil) {
		return REDValidationResultOptionalValid;
	}
	
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

@synthesize allowsNil = _allowsNil;

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
	
	if (_allowsNil && value == nil) {
		REDValidationResult result = REDValidationResultOptionalValid;
		[_delegate validationRule:self completedNetworkValidationOfComponent:component withResult:result error:nil];
		return result;
	}
	
	if (_block) {
		__weak typeof(self) weakSelf = self;
		_task = _block([component validatedValue], ^void(BOOL result, NSError *error) {
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
