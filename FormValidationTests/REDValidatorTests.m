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

static NSInteger const kTestValidationTextField1 = 1;
static NSInteger const kTestValidationTextField2 = 2;
static NSInteger const kTestValidationTextField3 = 3;
static NSString *const kTestTableViewCellIdentifier = @"TestTableViewCell";

@interface TestTextField : UITextField
@property (nonatomic, assign) BOOL willValidate;
@property (nonatomic, assign) BOOL didValidate;
@end

@implementation TestTextField

- (instancetype)init
{
	self = [super init];
	if (self) {
		self.text = @"test";
	}
	return self;
}

- (void)validatorWillValidateComponent:(REDValidator *)validator
{
	_willValidate = YES;
}

- (void)validator:(REDValidator *)validator didValidateComponentWithResult:(REDValidationResult)result error:(NSError *)error
{
	_didValidate  = YES;
}

@end

@interface TestTableViewCell : UITableViewCell
@property (nonatomic, strong) TestTextField *textField1;
@property (nonatomic, strong) TestTextField *textField2;
@property (nonatomic, strong) TestTextField *textField3;
@end

@implementation TestTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	if (self) {
		_textField1 = [[TestTextField alloc] init];
		[self.contentView addSubview:_textField1];
		_textField2 = [[TestTextField alloc] init];
		[self.contentView addSubview:_textField2];
		_textField3 = [[TestTextField alloc] init];
		[self.contentView addSubview:_textField3];
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
	_validator.validationComponents[@(kTestValidationTextField1)].uiComponent = cell.textField1;
	_validator.validationComponents[@(kTestValidationTextField2)].uiComponent = cell.textField2;
	_validator.validationComponents[@(kTestValidationTextField3)].uiComponent = cell.textField3;
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

- (void)validator:(REDValidator *)validator didValidateComponent:(UIView *)component result:(REDValidationResult)result error:(NSError *)error
{
	_didValidateComponent = YES;
}

@end

@interface REDValidator (TestExpose) <REDValidationComponentDelegate>
- (BOOL)evaluateValidationTree:(REDValidationTree *)tree revalidate:(BOOL)revalidate;
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

- (void)testPassingValidationTree
{
	[_testForm.validator addValidation:[[REDValidationComponent alloc] initWithIdentifier:@(kTestValidationTextField1) rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}]]];
	
	[_testForm.validator addValidation:[[REDValidationComponent alloc] initWithIdentifier:@(kTestValidationTextField2) rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}]]];
	
	_testForm.validator.validationTree = [REDValidationTree and:@[@(kTestValidationTextField1), @(kTestValidationTextField2)]];
	
	[self loadCells];
	XCTAssertEqual([_testForm.validator validate], REDValidationResultValid);
	XCTAssertEqual(_testForm.valid, REDValidationResultValid);
}

- (void)testFailingValidationTree
{
	[_testForm.validator addValidation:[[REDValidationComponent alloc] initWithIdentifier:@(kTestValidationTextField1) rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}]]];
	
	[_testForm.validator addValidation:[[REDValidationComponent alloc] initWithIdentifier:@(kTestValidationTextField2) rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return NO;
	}]]];
	
	_testForm.validator.validationTree = [REDValidationTree and:@[@(kTestValidationTextField1), @(kTestValidationTextField2)]];
	
	[self loadCells];
	XCTAssertEqual([_testForm.validator validate], REDValidationResultInvalid);
	XCTAssertEqual(_testForm.valid, REDValidationResultInvalid);
}

- (void)testComponentValidationsNotIncludedInValidationTreeAreANDed
{
	_testForm.validator.validationTree = [REDValidationTree single:@(kTestValidationTextField3)];
	
	[_testForm.validator addValidation:[[REDValidationComponent alloc] initWithIdentifier:@(kTestValidationTextField1) rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}]]];
	
	[_testForm.validator addValidation:[[REDValidationComponent alloc] initWithIdentifier:@(kTestValidationTextField2) rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}]]];
	
	[_testForm.validator addValidation:[[REDValidationComponent alloc] initWithIdentifier:@(kTestValidationTextField3) rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}]]];
	
	[self loadCells];
	XCTAssertEqual([_testForm.validator validate], REDValidationResultValid);
	XCTAssertEqual(_testForm.valid, REDValidationResultValid);
	
	[_testForm.validator addValidation:[[REDValidationComponent alloc] initWithIdentifier:@(kTestValidationTextField2) rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return NO;
	}]]];
	
	[self loadCells];
	XCTAssertEqual([_testForm.validator validate], REDValidationResultInvalid);
	XCTAssertEqual(_testForm.valid, REDValidationResultInvalid);
}

- (void)testComponentValidationsAreANDedIfValidationTreeIsNil
{
	_testForm.validator.validationTree = nil;
	
	[_testForm.validator addValidation:[[REDValidationComponent alloc] initWithIdentifier:@(kTestValidationTextField1) rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}]]];
	
	[_testForm.validator addValidation:[[REDValidationComponent alloc] initWithIdentifier:@(kTestValidationTextField2) rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}]]];
	
	[self loadCells];
	XCTAssertEqual([_testForm.validator validate], REDValidationResultValid);
	XCTAssertEqual(_testForm.valid, REDValidationResultValid);
	
	[_testForm.validator addValidation:[[REDValidationComponent alloc] initWithIdentifier:@(kTestValidationTextField2) rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return NO;
	}]]];
	
	[self loadCells];
	XCTAssertEqual([_testForm.validator validate], REDValidationResultInvalid);
	XCTAssertEqual(_testForm.valid, REDValidationResultInvalid);
}

- (void)testPassingNetworkComponentValidation
{
	XCTestExpectation *validationExpectation = [self expectationWithDescription:@"validated"];
	[_testForm.validator addValidation:[[REDValidationComponent alloc] initWithIdentifier:@(kTestValidationTextField1) rule:[REDNetworkValidationRule ruleWithBlock:^NSURLSessionTask *(id value, REDNetworkValidationRuleResultBlock completion) {
		NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:@"http://localhost"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
			completion(YES, nil);
			[validationExpectation fulfill];
		}];
		[task resume];
		return task;
	}]]];
	
	[self loadCells];
	XCTAssertEqual([_testForm.validator validate], REDValidationResultPending, @"Validation should be invalid before completing");
	
	[self waitForExpectationsWithTimeout:5.0 handler:nil];
	
	XCTAssertEqual(_testForm.valid, REDValidationResultValid, @"Validation should pass after completing");
}

- (void)testFailingNetworkComponentValidation
{
	XCTestExpectation *validationExpectation = [self expectationWithDescription:@"validated"];
	[_testForm.validator addValidation:[[REDValidationComponent alloc] initWithIdentifier:@(kTestValidationTextField1) rule:[REDNetworkValidationRule ruleWithBlock:^NSURLSessionTask *(id value, REDNetworkValidationRuleResultBlock completion) {
		NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:@"http://localhost"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
			completion(NO, nil);
			[validationExpectation fulfill];
		}];
		[task resume];
		return task;
	}]]];
	
	[self loadCells];
	XCTAssertEqual([_testForm.validator validate], REDValidationResultPending, @"Validation should be invalid before completing");
	
	[self waitForExpectationsWithTimeout:5.0 handler:nil];
	
	XCTAssertEqual(_testForm.valid, REDValidationResultInvalid, @"Validation should fail after completing");
}

- (void)testValidateResultIsAutomaticallyValidIfShouldValidateIsFalse
{
	_testForm.validator.shouldValidate = NO;
	
	[_testForm.validator addValidation:[[REDValidationComponent alloc] initWithIdentifier:@(kTestValidationTextField1) rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return NO;
	}]]];
	
	[self loadCells];
	XCTAssertEqual([_testForm.validator validate], REDValidationResultValid);
}

#pragma mark - evaluateValidationTree

- (void)testValidationTreeComponentsEvaluation
{
	REDValidationRule *rule = [REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}];
	
	[_testForm.validator addValidation:[[REDValidationComponent alloc] initWithIdentifier:@(kTestValidationTextField1) rule:rule]];
	[_testForm.validator addValidation:[[REDValidationComponent alloc] initWithIdentifier:@(kTestValidationTextField2) rule:rule]];
	
	[self loadCells];
	
	REDValidationComponent *textFieldComponent = _testForm.validator.validationComponents[@(kTestValidationTextField1)];
	REDValidationComponent *sliderComponent = _testForm.validator.validationComponents[@(kTestValidationTextField2)];
	
	_testForm.validator.validationTree = nil;
	XCTAssertFalse(textFieldComponent.validatedInValidationTree);
	XCTAssertFalse(sliderComponent.validatedInValidationTree);
	
	_testForm.validator.validationTree = [REDValidationTree single:@(kTestValidationTextField1)];
	XCTAssertTrue(textFieldComponent.validatedInValidationTree);
	XCTAssertFalse(sliderComponent.validatedInValidationTree);
	
	_testForm.validator.validationTree = [REDValidationTree or:@[@(kTestValidationTextField1), @(kTestValidationTextField2)]];
	XCTAssertTrue(textFieldComponent.validatedInValidationTree);
	XCTAssertTrue(sliderComponent.validatedInValidationTree);
}

#pragma mark - removeValidation:

- (void)testRemoveValidationRemovesValidation
{
	[_testForm.validator addValidation:[[REDValidationComponent alloc] initWithIdentifier:@(kTestValidationTextField1) rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}]]];
	XCTAssertNotNil(_testForm.validator.validationComponents[@(kTestValidationTextField1)]);
	
	XCTAssertTrue([_testForm.validator removeValidationWithIdentifier:@(kTestValidationTextField1)]);
	XCTAssertNil(_testForm.validator.validationComponents[@(kTestValidationTextField1)]);
}

- (void)testRemoveValidationDoesNotRemoveValidationIfItIsInValidationTree
{
	[_testForm.validator addValidation:[[REDValidationComponent alloc] initWithIdentifier:@(kTestValidationTextField1) rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}]]];
	_testForm.validator.validationTree = [REDValidationTree single:@(kTestValidationTextField1)];
	XCTAssertNotNil(_testForm.validator.validationComponents[@(kTestValidationTextField1)]);
	
	XCTAssertFalse([_testForm.validator removeValidationWithIdentifier:@(kTestValidationTextField1)]);
	XCTAssertNotNil(_testForm.validator.validationComponents[@(kTestValidationTextField1)]);
}

#pragma mark - setShouldValidate:forValidation:

- (void)testFormIsReEvaluatedAfterSettingShouldValidateComponent
{
	[_testForm.validator addValidation:[[REDValidationComponent alloc] initWithIdentifier:@(kTestValidationTextField1) rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}]]];
	XCTAssertEqual([_testForm.validator validate], REDValidationResultInvalid, @"Initial validation should fail");
	XCTAssertEqual(_testForm.valid, REDValidationResultInvalid);
	
	_testForm.validator.validationComponents[@(kTestValidationTextField1)].shouldValidate = NO;
	XCTAssertEqual(_testForm.valid, REDValidationResultValid, @"Validation after disabling shouldValidate on component should be successful");
}

#pragma mark - Delegate notifications

- (void)testDelegateIsNotifiedWhenComponentsAreValidated
{
	XCTAssertFalse(_testForm.willValidateComponent, @"willValidate should not have fired yet");
	[_testForm.validator validationComponent:nil willValidateUIComponent:nil];
	XCTAssertTrue(_testForm.willValidateComponent, @"willValidate should have fired");
	
	XCTAssertFalse(_testForm.didValidateComponent, @"didValidate should not have fired yet");
	[_testForm.validator validationComponent:nil didValidateUIComponent:nil result:0 error:nil];
	XCTAssertTrue(_testForm.didValidateComponent, @"didValidate should have fired");
}

- (void)testComponentIsNotifiedWhenItIsValidated
{
	TestTableViewCell *cell = (TestTableViewCell *)[_testForm tableView:_testForm.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
	TestTextField *textField = cell.textField1;
	
	XCTAssertFalse(textField.willValidate, @"willValidate should not have fired yet");
	[_testForm.validator validationComponent:nil willValidateUIComponent:textField];
	XCTAssertTrue(textField.willValidate, @"willValidate should have fired");
	
	XCTAssertFalse(textField.didValidate, @"didValidate should not have fired yet");
	[_testForm.validator validationComponent:nil didValidateUIComponent:textField result:0 error:nil];
	XCTAssertTrue(textField.didValidate, @"didValidate should have fired");
}

@end
