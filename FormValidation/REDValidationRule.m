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
@property (nonatomic, copy) REDValidationBlock block;
@end

@implementation REDValidationRule

+ (instancetype)ruleWithBlock:(REDValidationBlock)block
{
	return [[self alloc] initWithBlock:block];
}

- (instancetype)initWithBlock:(REDValidationBlock)block
{
	self = [super init];
	if (self) {
		_block = [block copy];
	}
	return self;
}

- (REDValidationResult)validate:(NSObject<REDValidatableComponent> *)component
{
	if (_block) {
		return _block([component validatedValue]) ? REDValidationResultSuccess : REDValidationResultFailure;
	} else {
		return REDValidationResultFailure;
	}
}

- (void)cancel
{
}

@end

@interface REDNetworkValidationRule ()
@property (nonatomic, copy) REDNetworkValidationBlock block;
@end

@implementation REDNetworkValidationRule {
	__weak NSURLSessionTask *_task;
}

+ (instancetype)ruleWithBlock:(REDNetworkValidationBlock)block
{
	return [[self alloc] initWithBlock:block];
}

- (instancetype)initWithBlock:(REDNetworkValidationBlock)block
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
	
	if (_block) {
		__weak typeof(self) weakSelf = self;
		_task = _block([component validatedValue], ^void(BOOL success, NSError *error) {
			__strong typeof(weakSelf) strongSelf = weakSelf;
			REDValidationResult result = success ? REDValidationResultSuccess : REDValidationResultFailure;
			[strongSelf.delegate validationRule:strongSelf completedNetworkValidationOfComponent:component withResult:result error:error];
		});
		
		return REDValidationResultPending;
	} else {
		return REDValidationResultFailure;
	}
}

- (void)cancel
{
	[_task cancel];
	_task = nil;
}

@end
