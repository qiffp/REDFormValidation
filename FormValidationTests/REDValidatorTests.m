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

static NSInteger const kTestValidationTextField = 1;
static NSInteger const kTestValidationSlider = 2;
static NSString *const kTestTableViewCellIdentifier = @"TestTableViewCell";

@interface TestTextField : UITextField
@property (nonatomic, assign) BOOL willValidate;
@property (nonatomic, assign) BOOL didValidate;
@end

@implementation TestTextField

- (void)validatorWillValidateComponent:(REDValidator *)validator
{
	_willValidate = YES;
}

- (void)validator:(REDValidator *)validator didValidateComponentWithResult:(REDValidationResult)result
{
	_didValidate = YES;
}

@end

@interface TestTableViewCell : UITableViewCell
@property (nonatomic, strong) TestTextField *textField;
@property (nonatomic, strong) UISlider *slider;
@end

@implementation TestTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	if (self) {
		_textField = [[TestTextField alloc] init];
		[self.contentView addSubview:_textField];
		
		_slider = [[UISlider alloc] init];
		[self.contentView addSubview:_slider];
	}
	return self;
}

@end

@interface TestTableViewForm : UIViewController <REDValidatorDelegate, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) REDValidator *validator;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, assign) REDValidationResult valid;
@property (nonatomic, assign) BOOL willValidateComponent;
@property (nonatomic, assign) BOOL didValidateComponent;
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
	
	_validator = [REDValidator new];
	_validator.delegate = self;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	TestTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kTestTableViewCellIdentifier forIndexPath:indexPath];
	[_validator setComponent:cell.textField forValidation:@(kTestValidationTextField)];
	[_validator setComponent:cell.slider forValidation:@(kTestValidationSlider)];
	return cell;
}

- (void)validator:(REDValidator *)validator didValidateFormWithResult:(REDValidationResult)result
{
	_valid = result;
}

- (void)validator:(REDValidator *)validator willValidateComponent:(UIView *)component
{
	_willValidateComponent = YES;
}

- (void)validator:(REDValidator *)validator didValidateComponent:(UIView *)component result:(REDValidationResult)result
{
	_didValidateComponent = YES;
}

@end

@interface REDValidator (TestExpose) <REDValidationComponentDelegate>
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
}

- (void)tearDown
{
	_testForm = nil;
	[super tearDown];
}

- (void)loadCells
{
	_testForm.view.frame = CGRectMake(0.0f, 0.0f, 100.0f, 100.0f);
	[_testForm.tableView layoutSubviews];
}

#pragma mark - validate

- (void)testPassingValidationBlock
{
	[_testForm.validator addValidation:@(kTestValidationTextField) validateOn:REDValidationEventAll rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}]];
	
	[_testForm.validator addValidation:@(kTestValidationSlider) validateOn:REDValidationEventAll rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return NO;
	}]];
	
	_testForm.validator.validationBlock = ^BOOL(REDValidator *validator) {
		return [validator validationIsValid:@(kTestValidationTextField)] | [validator validationIsValid:@(kTestValidationSlider)];
	};
	
	[self loadCells];
	XCTAssertEqual([_testForm.validator validate], REDValidationResultValid, @"Validation should pass");
	XCTAssertEqual(_testForm.valid, REDValidationResultValid, @"Validation should pass");
}

- (void)testFailingValidationBlock
{
	[_testForm.validator addValidation:@(kTestValidationTextField) validateOn:REDValidationEventAll rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}]];
	
	[_testForm.validator addValidation:@(kTestValidationSlider) validateOn:REDValidationEventAll rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return NO;
	}]];
	
	_testForm.validator.validationBlock = ^BOOL(REDValidator *validator) {
		return [validator validationIsValid:@(kTestValidationTextField)] & [validator validationIsValid:@(kTestValidationSlider)];
	};
	
	[self loadCells];
	XCTAssertEqual([_testForm.validator validate], REDValidationResultInvalid, @"Validation should fail");
	XCTAssertEqual(_testForm.valid, REDValidationResultInvalid, @"Validation should fail");
}

- (void)testComponentValidationsNotIncludedInValidationBlockAreANDed
{
	_testForm.validator.validationBlock = ^BOOL(REDValidator *validator) {
		return YES;
	};
	
	[_testForm.validator addValidation:@(kTestValidationTextField) validateOn:REDValidationEventAll rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}]];
	
	[_testForm.validator addValidation:@(kTestValidationSlider) validateOn:REDValidationEventAll rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}]];
	
	[self loadCells];
	XCTAssertEqual([_testForm.validator validate], REDValidationResultValid, @"Validation should pass");
	XCTAssertEqual(_testForm.valid, REDValidationResultValid, @"Validation should pass");
	
	[_testForm.validator addValidation:@(kTestValidationSlider) validateOn:REDValidationEventAll rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return NO;
	}]];
	
	[self loadCells];
	XCTAssertEqual([_testForm.validator validate], REDValidationResultInvalid, @"Validation should fail");
	XCTAssertEqual(_testForm.valid, REDValidationResultInvalid, @"Validation should fail");
}

- (void)testComponentValidationsAreANDedIfValidationBlockIsNil
{
	_testForm.validator.validationBlock = nil;
	
	[_testForm.validator addValidation:@(kTestValidationTextField) validateOn:REDValidationEventAll rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}]];
	
	[_testForm.validator addValidation:@(kTestValidationSlider) validateOn:REDValidationEventAll rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}]];
	
	[self loadCells];
	XCTAssertEqual([_testForm.validator validate], REDValidationResultValid, @"Validation should pass");
	XCTAssertEqual(_testForm.valid, REDValidationResultValid, @"Validation should pass");
	
	[_testForm.validator addValidation:@(kTestValidationSlider) validateOn:REDValidationEventAll rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return NO;
	}]];
	
	[self loadCells];
	XCTAssertEqual([_testForm.validator validate], REDValidationResultInvalid, @"Validation should fail");
	XCTAssertEqual(_testForm.valid, REDValidationResultInvalid, @"Validation should fail");
}

- (void)testPassingNetworkComponentValidation
{
	XCTestExpectation *validationExpectation = [self expectationWithDescription:@"validated"];
	[_testForm.validator addValidation:@(kTestValidationTextField) validateOn:REDValidationEventAll rule:[REDNetworkValidationRule ruleWithBlock:^NSURLSessionTask *(id value, REDNetworkValidationRuleResultBlock completion) {
		NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:@"http://localhost"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
			completion(YES, nil);
			
			[validationExpectation fulfill];
		}];
		[task resume];
		return task;
	}]];
	
	[self loadCells];
	XCTAssertEqual([_testForm.validator validate], REDValidationResultInvalid, @"Validation should be invalid before completing");
	
	[self waitForExpectationsWithTimeout:5.0 handler:nil];
	
	XCTAssertEqual(_testForm.valid, REDValidationResultValid, @"Validation should pass");
}

- (void)testFailingNetworkComponentValidation
{
	XCTestExpectation *validationExpectation = [self expectationWithDescription:@"validated"];
	[_testForm.validator addValidation:@(kTestValidationTextField) validateOn:REDValidationEventAll rule:[REDNetworkValidationRule ruleWithBlock:^NSURLSessionTask *(id value, REDNetworkValidationRuleResultBlock completion) {
		NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:@"http://localhost"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
			completion(NO, nil);
			
			[validationExpectation fulfill];
		}];
		[task resume];
		return task;
	}]];
	
	[self loadCells];
	XCTAssertEqual([_testForm.validator validate], REDValidationResultInvalid, @"Validation should be invalid before completing");
	
	[self waitForExpectationsWithTimeout:5.0 handler:nil];
	
	XCTAssertEqual(_testForm.valid, REDValidationResultInvalid, @"Validation should fail");
}

- (void)testValidateResultIsAutomaticallyValidIfShouldValidateIsFalse
{
	_testForm.validator.shouldValidate = NO;
	
	[_testForm.validator addValidation:@(kTestValidationTextField) validateOn:REDValidationEventAll rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return NO;
	}]];
	
	[self loadCells];
	XCTAssertEqual([_testForm.validator validate], REDValidationResultValid, @"Validation should pass");
}

#pragma mark - evaluateValidationBlock

- (void)testValidationBlockComponentsEvaluation
{
	REDValidationRule *rule = [REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}];
	[_testForm.validator addValidation:@(kTestValidationTextField) validateOn:REDValidationEventAll rule:rule];
	[_testForm.validator addValidation:@(kTestValidationSlider) validateOn:REDValidationEventAll rule:rule];
	
	[self loadCells];
	
	REDValidationComponent *textFieldComponent = _testForm.validator.validationComponents[@(kTestValidationTextField)];
	REDValidationComponent *sliderComponent = _testForm.validator.validationComponents[@(kTestValidationSlider)];
	
	_testForm.validator.validationBlock = nil;
	XCTAssertFalse(textFieldComponent.validatedInValidatorBlock, @"The text field is not validated in the block");
	XCTAssertFalse(sliderComponent.validatedInValidatorBlock, @"The slider is not validated in the block");
	
	_testForm.validator.validationBlock = ^BOOL(REDValidator *validator) {
		return [validator validationIsValid:@(kTestValidationTextField)];
	};
	XCTAssertTrue(textFieldComponent.validatedInValidatorBlock, @"The text field is validated in the block");
	XCTAssertFalse(sliderComponent.validatedInValidatorBlock, @"The slider is not validated in the block");
	
	_testForm.validator.validationBlock = ^BOOL(REDValidator *validator) {
		return [validator validationIsValid:@(kTestValidationTextField)] | [validator validationIsValid:@(kTestValidationSlider)];
	};
	XCTAssertTrue(textFieldComponent.validatedInValidatorBlock, @"The text field is validated in the block");
	XCTAssertTrue(sliderComponent.validatedInValidatorBlock, @"The slider is validated in the block");
}

#pragma mark - removeValidation:

- (void)testRemoveValidationRemovesValidation
{
	[_testForm.validator addValidation:@(kTestValidationTextField) validateOn:REDValidationEventAll rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}]];
	XCTAssertNotNil(_testForm.validator.validationComponents[@(kTestValidationTextField)], @"There should be a validation using the tag");
	
	BOOL success = [_testForm.validator removeValidation:@(kTestValidationTextField)];
	XCTAssertTrue(success, @"The removal should have been successful");
	XCTAssertNil(_testForm.validator.validationComponents[@(kTestValidationTextField)], @"The validation using the tag should have been removed");
}

- (void)testRemoveValidationDoesNotRemoveValidationIfItIsInValidationBlock
{
	[_testForm.validator addValidation:@(kTestValidationTextField) validateOn:REDValidationEventAll rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}]];
	_testForm.validator.validationBlock = ^BOOL(REDValidator *validator) {
		return [validator validationIsValid:@(kTestValidationTextField)];
	};
	XCTAssertNotNil(_testForm.validator.validationComponents[@(kTestValidationTextField)], @"There should be a validation using the tag");
	
	BOOL success = [_testForm.validator removeValidation:@(kTestValidationTextField)];
	XCTAssertFalse(success, @"The removal should have been failed");
	XCTAssertNotNil(_testForm.validator.validationComponents[@(kTestValidationTextField)], @"The validation using the tag should not have been removed");
}

#pragma mark - setShouldValidate:forValidation:

- (void)testFormIsReEvaluatedAfterSettingShouldValidateComponent
{
	[_testForm.validator addValidation:@(kTestValidationTextField) validateOn:REDValidationEventAll rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return NO;
	}]];
	XCTAssertEqual([_testForm.validator validate], REDValidationResultInvalid, @"Initial validation should fail");
	XCTAssertEqual(_testForm.valid, REDValidationResultInvalid, @"Initial validation should fail");
	
	[_testForm.validator setShouldValidate:NO forValidation:@(kTestValidationTextField)];
	XCTAssertEqual(_testForm.valid, REDValidationResultValid, @"Validation after disabling shouldValidate on component should be successful");
}

#pragma mark - Delegate notifications

- (void)testDelegateIsNotifiedWhenComponentsAreValidated
{
	XCTAssertFalse(_testForm.willValidateComponent, @"willValidate should not have fired yet");
	[_testForm.validator validationComponent:nil willValidateUIComponent:nil];
	XCTAssertTrue(_testForm.willValidateComponent, @"willValidate should have fired");
	
	XCTAssertFalse(_testForm.didValidateComponent, @"didValidate should not have fired yet");
	[_testForm.validator validationComponent:nil didValidateUIComponent:nil result:0];
	XCTAssertTrue(_testForm.didValidateComponent, @"didValidate should have fired");
}

- (void)testComponentIsNotifiedWhenItIsValidated
{
	TestTableViewCell *cell = (TestTableViewCell *)[_testForm tableView:_testForm.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
	TestTextField *textField = cell.textField;
	
	XCTAssertFalse(textField.willValidate, @"willValidate should not have fired yet");
	[_testForm.validator validationComponent:nil willValidateUIComponent:textField];
	XCTAssertTrue(textField.willValidate, @"willValidate should have fired");
	
	XCTAssertFalse(textField.didValidate, @"didValidate should not have fired yet");
	[_testForm.validator validationComponent:nil didValidateUIComponent:textField result:0];
	XCTAssertTrue(textField.didValidate, @"didValidate should have fired");
}

@end
