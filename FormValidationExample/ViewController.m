//
//  ViewController.m
//  FormValidationExample
//
//  Created by Sam Dye on 2016-03-04.
//  Copyright © 2016 Sam Dye. All rights reserved.
//

#import "ViewController.h"
#import "REDFormValidation.h"

static NSString *const kTextFieldCellIdentifier = @"textfieldcell";

typedef NS_ENUM(NSUInteger, FormCell) {
	FormCellFirstName,
	FormCellLastName,
	FormCellEmail,
	FormCellAddress,
	FormCellNote
};

@interface REDTextField : UITextField
@end

@implementation REDTextField : UITextField

- (void)validator:(REDValidator *)validator didValidateComponentWithResult:(BOOL)result
{
	self.textColor = result ? [UIColor greenColor] : [UIColor redColor];
}

@end

@interface REDTextFieldCell : UITableViewCell
@property (nonatomic, strong) REDTextField *textField;
@end

@implementation REDTextFieldCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	if (self) {
		_textField = [[REDTextField alloc] initWithFrame:CGRectZero];
		[self.contentView addSubview:_textField];
	}
	return self;
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	_textField.frame = self.bounds;
}

@end

@interface ViewController () <UITableViewDelegate, UITableViewDataSource, REDValidatorDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UILabel *headerView;
@property (nonatomic, strong) REDValidator *validator;
@end

@implementation ViewController

- (void)loadView
{
	[super loadView];
	
	_tableView = [[UITableView alloc] init];
	_tableView.delegate = self;
	_tableView.dataSource = self;
	
	_headerView = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 100.0f, 100.0f)];
	_headerView.text = @"Requires address and first/last name or email. Note is optional.";
	_headerView.numberOfLines = 2;
	_headerView.backgroundColor = [UIColor grayColor];
	_tableView.tableHeaderView = _headerView;
	
	[_tableView registerClass:[REDTextFieldCell class] forCellReuseIdentifier:kTextFieldCellIdentifier];
	
	self.view = _tableView;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	_validator = [[REDValidator alloc] init];
	_validator.delegate = self;
	[self setUpValidationRules];
}

- (void)setUpValidationRules
{
	REDValidationRule *lengthRule = [REDValidationRule ruleWithBlock:^BOOL(UIView *component) {
		return ((UITextField *)component).text.length > 0;
	}];
	[_validator addValidationWithTag:FormCellFirstName validateOn:REDValidationEventChange rule:lengthRule];
	[_validator addValidationWithTag:FormCellLastName validateOn:REDValidationEventChange rule:lengthRule];
	[_validator addValidationWithTag:FormCellEmail validateOn:REDValidationEventChange rule:lengthRule];
	[_validator addValidationWithTag:FormCellAddress validateOn:REDValidationEventChange rule:[REDValidationRule ruleWithBlock:^BOOL(UIView *component) {
		return ((UITextField *)component).text.length > 5;
	}]];
	[_validator addValidationWithTag:FormCellNote validateOn:REDValidationEventChange rule:[REDValidationRule ruleWithBlock:^BOOL(UIView *component) {
		return YES;
	}]];
	
	_validator.validationBlock = ^BOOL(REDValidator *v) {
		BOOL valid = ([v validationIsValid:FormCellFirstName] & [v validationIsValid:FormCellLastName]) | [v validationIsValid:FormCellEmail];
		valid &= [v validationIsValid:FormCellAddress];
		return valid;
	};
}

- (void)validator:(REDValidator *)validator didValidateFormWithResult:(BOOL)result
{
	_headerView.backgroundColor = result ? [UIColor greenColor] : [UIColor redColor];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	REDTextFieldCell *cell = [tableView dequeueReusableCellWithIdentifier:kTextFieldCellIdentifier forIndexPath:indexPath];
	
	switch (indexPath.row) {
		case FormCellFirstName: {
			cell.textField.placeholder = @"First name (length > 0)";
			break;
		}
		case FormCellLastName: {
			cell.textField.placeholder = @"Last name (length > 0)";
			break;
		}
		case FormCellEmail: {
			cell.textField.placeholder = @"Email (length > 0)";
			break;
		}
		case FormCellAddress: {
			cell.textField.placeholder = @"Address (length > 5)";
			break;
		}
		case FormCellNote: {
			cell.textField.placeholder = @"Note";
			break;
		}
		default: {
			break;
		}
	}
	
	[_validator setComponent:cell.textField forValidation:indexPath.row];
	
	return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 5;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

@end
