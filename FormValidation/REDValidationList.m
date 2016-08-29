//
//  REDValidationList.m
//  REDFormValidation
//
//  Created by Sam Dye on 2016-08-22.
//  Copyright © 2016 Sam Dye. All rights reserved.
//

#import "REDValidationList.h"
#import "REDValidationComponent.h"

typedef NS_ENUM(NSUInteger, REDValidationOperation) {
	REDValidationOperationAND,
	REDValidationOperationOR
};

@interface REDValidationListNode : NSObject
@property (nonatomic, strong, readonly) NSNumber *operation;
@property (nonatomic, strong, readonly) NSArray *identifiers;
@property (nonatomic, strong, readonly) NSArray<REDValidationList *> *lists;
@end

@implementation REDValidationListNode

- (instancetype)initWithOperation:(REDValidationOperation)operation objects:(NSArray *)objects
{
	self = [super init];
	if (self) {
		_operation = @(operation);
		
		id obj = objects.firstObject;
		if ([obj isKindOfClass:[REDValidationList class]]) {
			_lists = objects;
		} else {
			_identifiers = objects;
		}
	}
	return self;
}

@end

@implementation REDValidationList {
	NSMutableArray<REDValidationListNode *> *_nodes;
}

- (instancetype)initWithOperation:(REDValidationOperation)operation objects:(NSArray *)objects
{
	self = [super init];
	if (self) {
		_nodes = [NSMutableArray new];
		[_nodes addObject:[[REDValidationListNode alloc] initWithOperation:operation objects:objects]];
	}
	return self;
}

+ (REDValidationList *)single:(id)identifier
{
	return [[REDValidationList alloc] initWithOperation:REDValidationOperationOR objects:@[identifier]];
}

+ (REDValidationList *)and:(NSArray *)objects
{
	return [[REDValidationList alloc] initWithOperation:REDValidationOperationAND objects:objects];
}

+ (REDValidationList *)or:(NSArray *)objects
{
	return [[REDValidationList alloc] initWithOperation:REDValidationOperationOR objects:objects];
}

- (REDValidationList *)and:(NSArray *)objects
{
	[_nodes addObject:[[REDValidationListNode alloc] initWithOperation:REDValidationOperationAND objects:objects]];
	return self;
}

- (REDValidationList *)or:(NSArray *)objects
{
	[_nodes addObject:[[REDValidationListNode alloc] initWithOperation:REDValidationOperationOR objects:objects]];
	return self;
}

- (BOOL)validateComponents:(NSDictionary<id, REDValidationComponent *> *)components revalidate:(BOOL)revalidate
{
	BOOL finalResult = YES;
	BOOL hasInitializedFinalResult = NO;
	
	BOOL (^operation)(REDValidationListNode *, BOOL, BOOL) = ^BOOL (REDValidationListNode *node, BOOL previousResult, BOOL result) {
		BOOL operationResult = YES;
		
		switch (node.operation.unsignedIntegerValue) {
			case REDValidationOperationAND:
				operationResult = previousResult && result;
				break;
			case REDValidationOperationOR:
				operationResult = previousResult || result;
				break;
		}
		
		return operationResult;
	};
	
	for (REDValidationListNode *node in _nodes) {
		if (!hasInitializedFinalResult) {
			switch (node.operation.unsignedIntegerValue) {
				case REDValidationOperationAND:
					finalResult = YES;
					break;
				case REDValidationOperationOR:
					finalResult = NO;
					break;
			}
			
			hasInitializedFinalResult = YES;
		}
		
		if (node.identifiers) {
			for (id identifier in node.identifiers) {
				REDValidationComponent *component = components[identifier];
				REDValidationResult result = revalidate ? [component validate] : component.valid;
				finalResult = operation(node, finalResult, result == REDValidationResultValid || result == REDValidationResultDefaultValid);
			}
		} else {
			for (REDValidationList *list in node.lists) {
				BOOL result = [list validateComponents:components revalidate:revalidate];
				finalResult = operation(node, finalResult, result);
			}
		}
	}
	
	return finalResult;
}

- (void)evaluateComponents:(NSDictionary<id, REDValidationComponent *> *)components
{
	for (REDValidationComponent *component in components.allValues) {
		component.validatedInValidationList = NO;
	}
	
	for (REDValidationListNode *node in _nodes) {
		if (node.identifiers) {
			for (id identifier in node.identifiers) {
				components[identifier].validatedInValidationList = YES;
			}
		} else {
			for (REDValidationList *list in node.lists) {
				[list evaluateComponents:components];
			}
		}
	}
}

@end
