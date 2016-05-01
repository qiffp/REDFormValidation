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
static NSInteger const kTestValidationSwitch = 2;
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

- (void)validator:(REDValidator *)validator didValidateComponentWithResult:(BOOL)result
{
	_didValidate = YES;
}

@end

@interface TestTableViewCell : UITableViewCell
@property (nonatomic, strong) TestTextField *textField;
@property (nonatomic, strong) UISwitch *cellSwitch;
@end

@implementation TestTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	if (self) {
		_textField = [[TestTextField alloc] init];
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
	[_validator setComponent:cell.textField forValidation:kTestValidationTextField];
	[_validator setComponent:cell.cellSwitch forValidation:kTestValidationSwitch];
	return cell;
}

- (void)validator:(REDValidator *)validator didValidateFormWithResult:(BOOL)result
{
	_success = result;
}

- (void)validator:(REDValidator *)validator willValidateComponent:(UIView *)component
{
	_willValidateComponent = YES;
}

- (void)validator:(REDValidator *)validator didValidateComponent:(UIView *)component result:(BOOL)result
{
	_didValidateComponent = YES;
}

@end

@interface REDValidator (TestExpose) <REDValidationComponentDelegate>
- (BOOL)validate;
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

- (void)testPassingValidationBlock
{
	[_testForm.validator addValidationWithTag:kTestValidationTextField validateOn:REDValidationEventAll rule:[REDValidationRule ruleWithBlock:^BOOL(UIView *component) {
		return YES;
	}]];
	
	[_testForm.validator addValidationWithTag:kTestValidationSwitch validateOn:REDValidationEventAll rule:[REDValidationRule ruleWithBlock:^BOOL(UIView *component) {
		return NO;
	}]];
	
	_testForm.validator.validationBlock = ^BOOL(REDValidator *validator) {
		return [validator validationIsValid:kTestValidationTextField] || [validator validationIsValid:kTestValidationSwitch];
	};
	
	[self loadCells];
	XCTAssertTrue([_testForm.validator validate], @"Validation should pass");
	XCTAssertTrue(_testForm.success, @"Validation should pass");
}

- (void)testFailingValidationBlock
{
	[_testForm.validator addValidationWithTag:kTestValidationTextField validateOn:REDValidationEventAll rule:[REDValidationRule ruleWithBlock:^BOOL(UIView *component) {
		return YES;
	}]];
	
	[_testForm.validator addValidationWithTag:kTestValidationSwitch validateOn:REDValidationEventAll rule:[REDValidationRule ruleWithBlock:^BOOL(UIView *component) {
		return NO;
	}]];
	
	_testForm.validator.validationBlock = ^BOOL(REDValidator *validator) {
		return [validator validationIsValid:kTestValidationTextField] && [validator validationIsValid:kTestValidationSwitch];
	};
	
	[self loadCells];
	XCTAssertFalse([_testForm.validator validate], @"Validation should fail");
	XCTAssertFalse(_testForm.success, @"Validation should fail");
}

- (void)testComponentValidationsAreANDedIfValidationBlockIsNil
{
	_testForm.validator.validationBlock = nil;
	
	[_testForm.validator addValidationWithTag:kTestValidationTextField validateOn:REDValidationEventAll rule:[REDValidationRule ruleWithBlock:^BOOL(UIView *component) {
		return YES;
	}]];
	
	[_testForm.validator addValidationWithTag:kTestValidationSwitch validateOn:REDValidationEventAll rule:[REDValidationRule ruleWithBlock:^BOOL(UIView *component) {
		return YES;
	}]];
	
	[self loadCells];
	XCTAssertTrue([_testForm.validator validate], @"Validation should pass");
	XCTAssertTrue(_testForm.success, @"Validation should pass");
	
	[_testForm.validator addValidationWithTag:kTestValidationSwitch validateOn:REDValidationEventAll rule:[REDValidationRule ruleWithBlock:^BOOL(UIView *component) {
		return NO;
	}]];
	
	[self loadCells];
	XCTAssertFalse([_testForm.validator validate], @"Validation should fail");
	XCTAssertFalse(_testForm.success, @"Validation should fail");
}

- (void)testPassingNetworkComponentValidation
{
	XCTestExpectation *validationExpectation = [self expectationWithDescription:@"validated"];
	[_testForm.validator addValidationWithTag:kTestValidationTextField validateOn:REDValidationEventAll rule:[REDNetworkValidationRule ruleWithBlock:^NSURLSessionTask *(UIView *component, REDNetworkValidationResultBlock completion) {
		NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:@"http://localhost"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
			completion(YES, nil);
			
			[validationExpectation fulfill];
		}];
		[task resume];
		return task;
	}]];
	
	[self loadCells];
	XCTAssertFalse([_testForm.validator validate], @"Validation should be false while pending");
	
	[self waitForExpectationsWithTimeout:5.0 handler:nil];
	
	XCTAssertTrue(_testForm.success, @"Validation should pass");
}

- (void)testFailingNetworkComponentValidation
{
	XCTestExpectation *validationExpectation = [self expectationWithDescription:@"validated"];
	[_testForm.validator addValidationWithTag:kTestValidationTextField validateOn:REDValidationEventAll rule:[REDNetworkValidationRule ruleWithBlock:^NSURLSessionTask *(UIView *component, REDNetworkValidationResultBlock completion) {
		NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:@"http://localhost"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
			completion(NO, nil);
			
			[validationExpectation fulfill];
		}];
		[task resume];
		return task;
	}]];
	
	[self loadCells];
	XCTAssertFalse([_testForm.validator validate], @"Validation should be false while pending");
	
	[self waitForExpectationsWithTimeout:5.0 handler:nil];
	
	XCTAssertFalse(_testForm.success, @"Validation should fail");
}

- (void)testResultIsAutomaticallyTrueIfShouldValidateIsFalse
{
	_testForm.validator.shouldValidate = NO;
	
	[_testForm.validator addValidationWithTag:kTestValidationTextField validateOn:REDValidationEventAll rule:[REDValidationRule ruleWithBlock:^BOOL(UIView *component) {
		return NO;
	}]];
	
	[self loadCells];
	XCTAssertTrue([_testForm.validator validate], @"Validation should pass");
}

- (void)testValidationBlockComponentsEvaluation
{
	REDValidationRule *rule = [REDValidationRule ruleWithBlock:^BOOL(UIView *component) {
		return YES;
	}];
	[_testForm.validator addValidationWithTag:kTestValidationTextField validateOn:REDValidationEventAll rule:rule];
	[_testForm.validator addValidationWithTag:kTestValidationSwitch validateOn:REDValidationEventAll rule:rule];
	
	[self loadCells];
	
	_testForm.validator.validationBlock = nil;
	XCTAssertEqual(_testForm.validator.validationComponents[@(kTestValidationTextField)].validatedInValidatorBlock, NO, @"Neither component is validated in the block");
	XCTAssertEqual(_testForm.validator.validationComponents[@(kTestValidationSwitch)].validatedInValidatorBlock, NO, @"Neither component is validated in the block");
	
	_testForm.validator.validationBlock = ^BOOL(REDValidator *validator) {
		return [validator validationIsValid:kTestValidationTextField];
	};
	XCTAssertEqual(_testForm.validator.validationComponents[@(kTestValidationTextField)].validatedInValidatorBlock, YES, @"The text field is validated in the block");
	XCTAssertEqual(_testForm.validator.validationComponents[@(kTestValidationSwitch)].validatedInValidatorBlock, NO, @"The switch is not validated in the block");
	
	_testForm.validator.validationBlock = ^BOOL(REDValidator *validator) {
		return [validator validationIsValid:kTestValidationTextField] || [validator validationIsValid:kTestValidationSwitch];
	};
	XCTAssertEqual(_testForm.validator.validationComponents[@(kTestValidationTextField)].validatedInValidatorBlock, YES, @"The text field is validated in the block");
	XCTAssertEqual(_testForm.validator.validationComponents[@(kTestValidationSwitch)].validatedInValidatorBlock, YES, @"The switch is validated in the block");
}

- (void)testRemoveValidationRemovesValidation
{
	[_testForm.validator addValidationWithTag:kTestValidationTextField validateOn:REDValidationEventAll rule:[REDValidationRule ruleWithBlock:^BOOL(UIView *component) {
		return YES;
	}]];
	XCTAssertNotNil(_testForm.validator.validationComponents[@(kTestValidationTextField)], @"There should be a validation using the tag");
	
	BOOL success = [_testForm.validator removeValidation:kTestValidationTextField];
	XCTAssertTrue(success, @"The removal should have been successful");
	XCTAssertNil(_testForm.validator.validationComponents[@(kTestValidationTextField)], @"The validation using the tag should have been removed");
}

- (void)testRemoveValidationDoesNotRemoveValidationIfItIsInValidationBlock
{
	[_testForm.validator addValidationWithTag:kTestValidationTextField validateOn:REDValidationEventAll rule:[REDValidationRule ruleWithBlock:^BOOL(UIView *component) {
		return YES;
	}]];
	_testForm.validator.validationBlock = ^BOOL(REDValidator *validator) {
		return [validator validationIsValid:kTestValidationTextField];
	};
	XCTAssertNotNil(_testForm.validator.validationComponents[@(kTestValidationTextField)], @"There should be a validation using the tag");
	
	BOOL success = [_testForm.validator removeValidation:kTestValidationTextField];
	XCTAssertFalse(success, @"The removal should have been failed");
	XCTAssertNotNil(_testForm.validator.validationComponents[@(kTestValidationTextField)], @"The validation using the tag should not have been removed");
}

- (void)testFormIsReEvaluatedAfterSettingShouldValidateComponent
{
	[_testForm.validator addValidationWithTag:kTestValidationTextField validateOn:REDValidationEventAll rule:[REDValidationRule ruleWithBlock:^BOOL(UIView *component) {
		return NO;
	}]];
	XCTAssertFalse([_testForm.validator validate], @"Initial validation should fail");
	XCTAssertFalse(_testForm.success, @"Initial validation should fail");
	
	[_testForm.validator setShouldValidate:NO forValidation:kTestValidationTextField];
	XCTAssertTrue(_testForm.success, @"Validation after disabling shouldValidate on component should be successful");
}

- (void)testDelegateIsNotifiedWhenComponentsAreValidated
{
	XCTAssertFalse(_testForm.willValidateComponent, @"");
	[_testForm.validator validationComponent:nil willValidateUIComponent:nil];
	XCTAssertTrue(_testForm.willValidateComponent, @"");
	
	XCTAssertFalse(_testForm.didValidateComponent, @"");
	[_testForm.validator validationComponent:nil didValidateUIComponent:nil result:YES];
	XCTAssertTrue(_testForm.didValidateComponent, @"");
}

- (void)testComponentIsNotifiedWhenItIsValidated
{
	TestTableViewCell *cell = (TestTableViewCell *)[_testForm tableView:_testForm.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
	TestTextField *textField = cell.textField;
	
	XCTAssertFalse(textField.willValidate, @"");
	[_testForm.validator validationComponent:nil willValidateUIComponent:textField];
	XCTAssertTrue(textField.willValidate, @"");
	
	XCTAssertFalse(textField.didValidate, @"");
	[_testForm.validator validationComponent:nil didValidateUIComponent:textField result:YES];
	XCTAssertTrue(textField.didValidate, @"");
}

@end
