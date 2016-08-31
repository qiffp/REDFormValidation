//
//  REDValidationTree.m
//  REDFormValidation
//
//  Created by Sam Dye on 2016-08-22.
//  Copyright © 2016 Sam Dye. All rights reserved.
//

#import "REDValidationTree.h"
#import "REDValidationComponent.h"

typedef NS_ENUM(NSUInteger, REDValidationOperation) {
	REDValidationOperationAND,
	REDValidationOperationOR
};

@interface REDValidationTreeNode : NSObject
@property (nonatomic, strong, readonly) NSNumber *operation;
@property (nonatomic, strong, readonly) NSArray *identifiers;
@property (nonatomic, strong, readonly) NSArray<REDValidationTree *> *trees;
@end

@implementation REDValidationTreeNode

- (instancetype)initWithOperation:(REDValidationOperation)operation objects:(NSArray *)objects
{
	self = [super init];
	if (self) {
		_operation = @(operation);
		
		id obj = objects.firstObject;
		if ([obj isKindOfClass:[REDValidationTree class]]) {
			_trees = objects;
		} else {
			_identifiers = objects;
		}
	}
	return self;
}

@end

@implementation REDValidationTree {
	NSMutableArray<REDValidationTreeNode *> *_nodes;
}

- (instancetype)initWithOperation:(REDValidationOperation)operation objects:(NSArray *)objects
{
	self = [super init];
	if (self) {
		_nodes = [NSMutableArray new];
		[_nodes addObject:[[REDValidationTreeNode alloc] initWithOperation:operation objects:objects]];
	}
	return self;
}

+ (REDValidationTree *)single:(id)identifier
{
	return [[REDValidationTree alloc] initWithOperation:REDValidationOperationOR objects:@[identifier]];
}

+ (REDValidationTree *)and:(NSArray *)objects
{
	return [[REDValidationTree alloc] initWithOperation:REDValidationOperationAND objects:objects];
}

+ (REDValidationTree *)or:(NSArray *)objects
{
	return [[REDValidationTree alloc] initWithOperation:REDValidationOperationOR objects:objects];
}

- (REDValidationTree *)and:(NSArray *)objects
{
	[_nodes addObject:[[REDValidationTreeNode alloc] initWithOperation:REDValidationOperationAND objects:objects]];
	return self;
}

- (REDValidationTree *)or:(NSArray *)objects
{
	[_nodes addObject:[[REDValidationTreeNode alloc] initWithOperation:REDValidationOperationOR objects:objects]];
	return self;
}

- (BOOL)validateComponents:(NSDictionary<id, REDValidationComponent *> *)components revalidate:(BOOL)revalidate
{
	BOOL finalResult = YES;
	BOOL hasInitializedFinalResult = NO;
	
	BOOL (^operation)(REDValidationTreeNode *, BOOL, BOOL) = ^BOOL (REDValidationTreeNode *node, BOOL previousResult, BOOL result) {
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
	
	for (REDValidationTreeNode *node in _nodes) {
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
				if (component == nil) {
					NSLog(@"<REDFormValidation WARNING> Identifier '%@' used in the validation tree is not associated with a component. This will always validate as REDValidationResultUnvalidated", identifier);
				}
				
				REDValidationResult result = revalidate ? [component validate] : component.valid;
				finalResult = operation(node, finalResult, result == REDValidationResultValid || result == REDValidationResultDefaultValid);
			}
		} else {
			for (REDValidationTree *tree in node.trees) {
				BOOL result = [tree validateComponents:components revalidate:revalidate];
				finalResult = operation(node, finalResult, result);
			}
		}
	}
	
	return finalResult;
}

- (void)evaluateComponents:(NSDictionary<id, REDValidationComponent *> *)components
{
	[self evaluateComponents:components resetValues:YES];
}

- (void)evaluateComponents:(NSDictionary<id, REDValidationComponent *> *)components resetValues:(BOOL)resetValues
{
	if (resetValues) {
		for (REDValidationComponent *component in components.allValues) {
			component.validatedInValidationTree = NO;
		}
	}
	
	for (REDValidationTreeNode *node in _nodes) {
		if (node.identifiers) {
			for (id identifier in node.identifiers) {
				components[identifier].validatedInValidationTree = YES;
			}
		} else {
			for (REDValidationTree *tree in node.trees) {
				[tree evaluateComponents:components resetValues:NO];
			}
		}
	}
}

@end
