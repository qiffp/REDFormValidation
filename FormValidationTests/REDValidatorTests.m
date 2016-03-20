//
//  ValidatorTests.m
//  FormValidation
//
//  Created by Sam Dye on 2016-03-06.
//  Copyright © 2016 Sam Dye. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "REDFormValidation.h"
#import "REDValidationComponent.h"

static NSInteger const kTestTextFieldTag = 1;
static NSInteger const kTestSwitchTag = 2;
static NSString *const kTestTableViewCellIdentifier = @"TestTableViewCell";

@interface TestTableViewCell : UITableViewCell
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UISwitch *cellSwitch;
@end

@implementation TestTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	if (self) {
		_textField = [[UITextField alloc] init];
		[self.contentView addSubview:_textField];
		
		_cellSwitch = [[UISwitch alloc] init];
		[self.contentView addSubview:_cellSwitch];
	}
	return self;
}

@end

@interface TestTableViewForm : UIViewController <REDValidatorDelegate, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) REDValidator *validator;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, assign) BOOL success;
@property (nonatomic, assign) BOOL delegateMethodCalled;
@end

@implementation TestTableViewForm

- (void)loadView
{
	[super loadView];
	
	_tableView = [[UITableView alloc] init];
	_tableView.dataSource = self;
	_tableView.delegate = self;
	
	self.view = _tableView;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	[_tableView registerClass:[TestTableViewCell class] forCellReuseIdentifier:kTestTableViewCellIdentifier];
	
	_validator = [[REDValidator alloc] initWithView:_tableView];
	_validator.delegate = self;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	TestTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kTestTableViewCellIdentifier forIndexPath:indexPath];
	cell.textField.tag = kTestTextFieldTag;
	cell.cellSwitch.tag = kTestSwitchTag;
	return cell;
}

// not implemented by REDValidator
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	_delegateMethodCalled = YES;
	return 0.0f;
}

// implemented by REDValidator
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
	_delegateMethodCalled = YES;
}

- (void)validator:(REDValidator *)validator didValidateFormWithResult:(BOOL)result
{
	_success = result;
}

@end

@interface REDValidator (TestHelper)
@property (nonatomic, strong, readonly) NSDictionary<NSNumber *, REDValidationComponent *> *validationComponents;
@end

@implementation REDValidator (TestHelper)

- (NSDictionary *)validationComponents
{
	return [[self valueForKey:@"_validationComponents"] copy];
}

@end

@interface REDValidatorTests : XCTestCase
@end

@implementation REDValidatorTests {
	TestTableViewForm *_testForm;
}

- (void)setUp
{
	[super setUp];
	
	_testForm = [TestTableViewForm new];
	[_testForm loadView];
	[_testForm viewDidLoad];
	
	_testForm.view.frame = CGRectMake(0.0f, 0.0f, 100.0f, 100.0f);
	[_testForm.tableView layoutSubviews];
	
	_testForm.validator.validationBlock = ^BOOL(REDValidator *validator) {
		return [validator componentWithTagIsValid:kTestTextFieldTag];
	};
}

- (void)tearDown
{
	_testForm = nil;
	[super tearDown];
}

- (void)testPassingValidationBlock
{
	[_testForm.validator setRule:[REDValidationRule ruleWithBlock:^BOOL(UIView *component) {
		return YES;
	}] forComponentWithTag:kTestTextFieldTag validateOn:REDValidationEventAll];
	
	[_testForm.validator setRule:[REDValidationRule ruleWithBlock:^BOOL(UIView *component) {
		return NO;
	}] forComponentWithTag:kTestSwitchTag validateOn:REDValidationEventAll];
	
	_testForm.validator.validationBlock = ^BOOL(REDValidator *validator) {
		return [validator componentWithTagIsValid:kTestTextFieldTag] || [validator componentWithTagIsValid:kTestSwitchTag];
	};
	
	XCTAssertTrue([_testForm.validator validate], @"Validation should pass");
	XCTAssertTrue(_testForm.success, @"Validation should pass");
}

- (void)testFailingValidationBlock
{
	[_testForm.validator setRule:[REDValidationRule ruleWithBlock:^BOOL(UIView *component) {
		return YES;
	}] forComponentWithTag:kTestTextFieldTag validateOn:REDValidationEventAll];
	
	[_testForm.validator setRule:[REDValidationRule ruleWithBlock:^BOOL(UIView *component) {
		return NO;
	}] forComponentWithTag:kTestSwitchTag validateOn:REDValidationEventAll];
	
	_testForm.validator.validationBlock = ^BOOL(REDValidator *validator) {
		return [validator componentWithTagIsValid:kTestTextFieldTag] && [validator componentWithTagIsValid:kTestSwitchTag];
	};
	
	XCTAssertFalse([_testForm.validator validate], @"Validation should fail");
	XCTAssertFalse(_testForm.success, @"Validation should fail");
}

- (void)testComponentValidationsAreANDedIfValidationBlockIsNil
{
	_testForm.validator.validationBlock = nil;
	
	[_testForm.validator setRule:[REDValidationRule ruleWithBlock:^BOOL(UIView *component) {
		return YES;
	}] forComponentWithTag:kTestTextFieldTag validateOn:REDValidationEventAll];
	
	[_testForm.validator setRule:[REDValidationRule ruleWithBlock:^BOOL(UIView *component) {
		return YES;
	}] forComponentWithTag:kTestSwitchTag validateOn:REDValidationEventAll];
	
	XCTAssertTrue([_testForm.validator validate], @"Validation should pass");
	XCTAssertTrue(_testForm.success, @"Validation should pass");
	
	[_testForm.validator setRule:[REDValidationRule ruleWithBlock:^BOOL(UIView *component) {
		return NO;
	}] forComponentWithTag:kTestSwitchTag validateOn:REDValidationEventAll];
	
	XCTAssertFalse([_testForm.validator validate], @"Validation should fail");
	XCTAssertFalse(_testForm.success, @"Validation should fail");
}

- (void)testPassingNetworkComponentValidation
{
	XCTestExpectation *validationExpectation = [self expectationWithDescription:@"validated"];
	[_testForm.validator setRule:[REDNetworkValidationRule ruleWithBlock:^NSURLSessionTask *(UIView *component, REDNetworkValidationResultBlock completion) {
		NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:@"http://localhost"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
			completion(YES, nil);
			
			[validationExpectation fulfill];
		}];
		[task resume];
		return task;
	}] forComponentWithTag:kTestTextFieldTag validateOn:REDValidationEventAll];
	
	XCTAssertFalse([_testForm.validator validate], @"Validation should be false while pending");
	
	[self waitForExpectationsWithTimeout:5.0 handler:nil];
	
	XCTAssertTrue(_testForm.success, @"Validation should pass");
}

- (void)testFailingNetworkComponentValidation
{
	XCTestExpectation *validationExpectation = [self expectationWithDescription:@"validated"];
	[_testForm.validator setRule:[REDNetworkValidationRule ruleWithBlock:^NSURLSessionTask *(UIView *component, REDNetworkValidationResultBlock completion) {
		NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:@"http://localhost"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
			completion(NO, nil);
			
			[validationExpectation fulfill];
		}];
		[task resume];
		return task;
	}] forComponentWithTag:kTestTextFieldTag validateOn:REDValidationEventAll];
	
	XCTAssertFalse([_testForm.validator validate], @"Validation should be false while pending");
	
	[self waitForExpectationsWithTimeout:5.0 handler:nil];
	
	XCTAssertFalse(_testForm.success, @"Validation should fail");
}

- (void)testResultIsAutomaticallyTrueIfShouldValidateIsFalse
{
	_testForm.validator.shouldValidate = NO;
	
	[_testForm.validator setRule:[REDValidationRule ruleWithBlock:^BOOL(UIView *component) {
		return NO;
	}] forComponentWithTag:kTestTextFieldTag validateOn:REDValidationEventAll];
	
	XCTAssertTrue([_testForm.validator validate], @"Validation should pass");
}

- (void)testValidationBlockComponentsEvaluation
{
	REDValidationRule *rule = [REDValidationRule ruleWithBlock:^BOOL(UIView *component) {
		return YES;
	}];
	[_testForm.validator setRule:rule forComponentWithTag:kTestTextFieldTag validateOn:REDValidationEventAll];
	[_testForm.validator setRule:rule forComponentWithTag:kTestSwitchTag validateOn:REDValidationEventAll];
	
	_testForm.validator.validationBlock = nil;
	XCTAssertEqual(_testForm.validator.validationComponents[@(kTestTextFieldTag)].validatedInValidatorBlock, NO, @"Neither component is validated in the block");
	XCTAssertEqual(_testForm.validator.validationComponents[@(kTestSwitchTag)].validatedInValidatorBlock, NO, @"Neither component is validated in the block");
	
	_testForm.validator.validationBlock = ^BOOL(REDValidator *validator) {
		return [validator componentWithTagIsValid:kTestTextFieldTag];
	};
	XCTAssertEqual(_testForm.validator.validationComponents[@(kTestTextFieldTag)].validatedInValidatorBlock, YES, @"The text field is validated in the block");
	XCTAssertEqual(_testForm.validator.validationComponents[@(kTestSwitchTag)].validatedInValidatorBlock, NO, @"The switch is not validated in the block");
	
	_testForm.validator.validationBlock = ^BOOL(REDValidator *validator) {
		return [validator componentWithTagIsValid:kTestTextFieldTag] || [validator componentWithTagIsValid:kTestSwitchTag];
	};
	XCTAssertEqual(_testForm.validator.validationComponents[@(kTestTextFieldTag)].validatedInValidatorBlock, YES, @"The text field is validated in the block");
	XCTAssertEqual(_testForm.validator.validationComponents[@(kTestSwitchTag)].validatedInValidatorBlock, YES, @"The switch is validated in the block");
}

- (void)testUnimplementedComponentDelegateMethodsGetPassedToOriginalDelegate
{
	_testForm.delegateMethodCalled = NO;
	if ([_testForm.validator respondsToSelector:@selector(tableView:heightForHeaderInSection:)]) {
		[(id<UITableViewDelegate>)_testForm.validator tableView:_testForm.tableView heightForHeaderInSection:0];
	}
	XCTAssertTrue(_testForm.delegateMethodCalled, @"Delegate method should have been called on original delegate");
}

- (void)testImplementedComponentDelegateMethodsGetPassedToOriginalDelegate
{
	_testForm.delegateMethodCalled = NO;
	if ([_testForm respondsToSelector:@selector(tableView:willDisplayCell:forRowAtIndexPath:)]) {
		[(id<UITableViewDelegate>)_testForm.validator tableView:_testForm.tableView willDisplayCell:[UITableViewCell new] forRowAtIndexPath:[NSIndexPath indexPathWithIndex:0]];
	}
	XCTAssertTrue(_testForm.delegateMethodCalled, @"Delegate method should have been called on original delegate");
}

@end
