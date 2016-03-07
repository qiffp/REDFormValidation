//
//  REDValidationRule.h
//  REDFormValidation
//
//  Created by Sam Dye on 2016-03-04.
//  Copyright © 2016 Sam Dye. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef BOOL (^REDValidationBlock)(UIView *component);

typedef void (^REDNetworkValidationResultBlock)(BOOL success, NSError *error);
typedef NSURLSessionTask * (^REDNetworkValidationBlock)(UIView *component, REDNetworkValidationResultBlock completion);

typedef NS_ENUM(NSInteger, REDValidationResult) {
	REDValidationResultUnknown = (1 << 0),
	REDValidationResultFailure = (1 << 1),
	REDValidationResultSuccess = (1 << 2),
	REDValidationResultPending = (1 << 3)
};

@protocol REDValidationRuleProtocol <NSObject>
- (REDValidationResult)validate:(UIView *)component;
- (void)cancel;
@end

@protocol REDNetworkValidationRuleDelegate <NSObject>
- (void)validationRule:(id<REDValidationRuleProtocol>)rule didValidateWithResult:(REDValidationResult)result error:(NSError *)error;
@end

@interface REDValidationRule : NSObject <REDValidationRuleProtocol>

+ (instancetype)ruleWithBlock:(REDValidationBlock)block;

@end

@interface REDNetworkValidationRule : NSObject <REDValidationRuleProtocol>

@property (nonatomic, weak) id<REDNetworkValidationRuleDelegate> delegate;

+ (instancetype)ruleWithBlock:(REDNetworkValidationBlock)block;

@end
