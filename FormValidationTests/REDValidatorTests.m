//
//  ValidatorTests.m
//  FormValidation
//
//  Created by Sam Dye on 2016-03-06.
//  Copyright © 2016 Sam Dye. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "REDFormValidation.h"

static NSInteger const kTestTextFieldTag = 123;
static NSString *const kTestTableViewCellIdentifier = @"TestTableViewCell";

@interface TestTableViewCell : UITableViewCell
@property (nonatomic, strong) UITextField *textField;
@end

@implementation TestTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	if (self) {
		_textField = [[UITextField alloc] init];
		[self.contentView addSubview:_textField];
	}
	return self;
}

@end

@interface TestTableViewForm : UIViewController <REDValidatorDelegate, UITableViewDataSource>
@property (nonatomic, strong) REDValidator *validator;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, assign) BOOL success;
@end

@implementation TestTableViewForm

- (void)loadView
{
	[super loadView];
	
	_tableView = [[UITableView alloc] init];
	_tableView.dataSource = self;
	
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
	return cell;
}

- (void)validator:(REDValidator *)validator didValidateFormWithResult:(BOOL)result
{
	_success = result;
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
		return [validator validationComponentWithTag:kTestTextFieldTag].valid;
	};
}

- (void)tearDown
{
	_testForm = nil;
	[super tearDown];
}

- (void)testPass
{
	[_testForm.validator setRule:[REDValidationRule ruleWithBlock:^BOOL(UIView *component) {
		return [component isKindOfClass:[UITextField class]];
	}] forComponentWithTag:kTestTextFieldTag validateOn:REDValidationEventAll];
	
	XCTAssertTrue([_testForm.validator validate], @"Validation should pass");
}

- (void)testFail
{
	[_testForm.validator setRule:[REDValidationRule ruleWithBlock:^BOOL(UIView *component) {
		return [component isKindOfClass:[UISwitch class]];
	}] forComponentWithTag:kTestTextFieldTag validateOn:REDValidationEventAll];
	
	XCTAssertFalse([_testForm.validator validate], @"Validation should fail");
}

- (void)testNetworkPass
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

- (void)testNetworkFail
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

@end
