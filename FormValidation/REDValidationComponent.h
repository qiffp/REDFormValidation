//
//  REDValidationComponent.h
//  REDFormValidation
//
//  Created by Sam Dye on 2016-03-04.
//  Copyright © 2016 Sam Dye. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "REDValidationRule.h"

typedef NS_ENUM(NSInteger, REDValidationEvent) {
	REDValidationEventChange = (1 << 0),
	REDValidationEventBeginEditing = (1 << 1),
	REDValidationEventEndEditing = (1 << 2),
	REDValidationEventAll = (1 << 3)
};

@class REDValidationComponent;

@protocol REDValidationComponentDelegate <NSObject>
- (void)validationComponent:(REDValidationComponent *)validationComponent willValidateUIComponent:(UIControl *)uiComponent;
- (void)validationComponent:(REDValidationComponent *)validationComponent didValidateUIComponent:(UIControl *)uiComponent result:(BOOL)result;
@end

@interface REDValidationComponent : NSObject

@property (nonatomic, strong) id<REDValidationRuleProtocol> rule;
@property (nonatomic, weak) UIControl *uiComponent;
@property (nonatomic, weak) id<REDValidationComponentDelegate> delegate;
@property (nonatomic, assign) NSInteger tag;
@property (nonatomic, assign) BOOL validated;

- (instancetype)initWithUIComponent:(UIControl *)uiComponent validateOn:(REDValidationEvent)event;

- (BOOL)validateWithCallbacks:(BOOL)callback;

@end

@interface REDValidationComponent (Public)

@property (nonatomic, assign) BOOL valid;

@end