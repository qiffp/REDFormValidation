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

- (void)validator:(REDValidator *)validator didValidateUIComponentWithResult:(REDValidationResult)result error:(NSError *)error
{
	if (result == REDValidationResultValid) {
		self.textColor = [UIColor greenColor];
	} else if (result == REDValidationResultPending) {
		self.textColor = [UIColor purpleColor];
	} else {
		if (validator.valid == REDValidationResultValid) {
			self.textColor = [UIColor grayColor];
		} else {
			self.textColor = [UIColor redColor];
		}
	}
}

@end

@protocol REDTextFieldCellDelegate <NSObject>
- (void)textFieldUpdated:(REDTextField *)textField;
@end

@interface REDTextFieldCell : UITableViewCell
@property (nonatomic, strong) REDTextField *textField;
@property (nonatomic, weak) id<REDTextFieldCellDelegate> delegate;
@end

@implementation REDTextFieldCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	if (self) {
		_textField = [[REDTextField alloc] initWithFrame:CGRectZero];
		[self.contentView addSubview:_textField];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textChanged:) name:UITextFieldTextDidChangeNotification object:nil];
	}
	return self;
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	_textField.frame = self.bounds;
}

- (void)textChanged:(NSNotification *)notification
{
	[_delegate textFieldUpdated:notification.object];
}

@end

@interface ViewController () <UITableViewDelegate, UITableViewDataSource, REDValidatorDelegate, REDTextFieldCellDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UILabel *headerView;
@property (nonatomic, strong) REDValidator *validator;
@end

@implementation ViewController {
	NSString *_firstName;
	NSString *_lastName;
	NSString *_email;
	NSString *_address;
	NSString *_note;
}

- (void)loadView
{
	[super loadView];
	
	UIView *contentView = [[UIView alloc] init];
	contentView.backgroundColor = [UIColor lightGrayColor];
	
	_tableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0f, 50.0f, 0.0f, 200.0f)];
	_tableView.delegate = self;
	_tableView.dataSource = self;
	_tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	_tableView.rowHeight = 80.0f;
	[contentView addSubview:_tableView];
	
	_headerView = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 0.0f, 100.0f)];
	_headerView.text = @"Requires address and first/last name or email. Note is optional.";
	_headerView.numberOfLines = 2;
	_headerView.backgroundColor = [UIColor grayColor];
	_tableView.tableHeaderView = _headerView;
	
	[_tableView registerClass:[REDTextFieldCell class] forCellReuseIdentifier:kTextFieldCellIdentifier];
	
	self.view = contentView;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	_validator = [[REDValidator alloc] init];
	_validator.delegate = self;
	_validator.inputDelay = 1.0;
	[self setUpValidationRules];
}

- (void)setUpValidationRules
{
	REDValidationRule *lengthRule = [REDValidationRule ruleWithBlock:^BOOL(NSString *text) {
		return text.length > 0;
	}];
	[_validator addValidation:[REDValidation validationWithIdentifier:@(FormCellFirstName) rule:lengthRule]];
	[_validator addValidation:[REDValidation validationWithIdentifier:@(FormCellLastName) rule:lengthRule]];
	[_validator addValidation:[REDValidation validationWithIdentifier:@(FormCellEmail) rule:[REDNetworkValidationRule ruleWithBlock:^NSURLSessionTask *(NSString *text, REDNetworkValidationRuleResultBlock completion) {
		NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:@"https://www.github.com/qiffp"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
			completion([text containsString:@"@"], nil);
		}];
		[task resume];
		return task;
	}]]];
	[_validator addValidation:[REDValidation validationWithIdentifier:@(FormCellAddress) rule:[REDValidationRule ruleWithBlock:^BOOL(NSString *text) {
		return text.length > 5;
	}]]];
	
	[_validator addValidation:[REDValidation validationWithIdentifier:@(FormCellNote) initialValue:nil allowDefault:YES validationEvent:REDValidationEventAll rule:[REDValidationRule ruleWithBlock:^BOOL(id value) {
		return YES;
	}]]];
	
	_validator.validationTree = [REDValidationTree and:@[
														 [REDValidationTree or:@[
																				 [REDValidationTree and:@[@(FormCellFirstName), @(FormCellLastName)]],
																				 [REDValidationTree single:@(FormCellEmail)]
																				 ]],
														 [REDValidationTree single:@(FormCellAddress)]
														 ]];
}

- (void)validator:(REDValidator *)validator didValidateFormWithResult:(REDValidationResult)result
{
	self.view.backgroundColor = result == REDValidationResultValid ? [UIColor greenColor] : [UIColor redColor];
}

- (void)textFieldUpdated:(REDTextField *)textField
{
	NSString *text = textField.text;
	switch (textField.tag) {
		case FormCellFirstName:
			_firstName = text;
			break;
		case FormCellLastName:
			_lastName = text;
			break;
		case FormCellEmail:
			_email = text;
			break;
		case FormCellAddress:
			_address = text;
			break;
		case FormCellNote:
			_note = text;
			break;
		default:
			break;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	REDTextFieldCell *cell = [tableView dequeueReusableCellWithIdentifier:kTextFieldCellIdentifier forIndexPath:indexPath];
	cell.delegate = self;
	
	switch (indexPath.row) {
		case FormCellFirstName:
			cell.textField.placeholder = @"First name (length > 0)";
			cell.textField.text = _firstName;
			break;
		case FormCellLastName:
			cell.textField.placeholder = @"Last name (length > 0)";
			cell.textField.text = _lastName;
			break;
		case FormCellEmail:
			cell.textField.placeholder = @"Email (length > 0 and contains '@')";
			cell.textField.text = _email;
			break;
		case FormCellAddress:
			cell.textField.placeholder = @"Address (length > 5)";
			cell.textField.text = _address;
			break;
		case FormCellNote:
			cell.textField.placeholder = @"Note";
			cell.textField.text = _note;
			break;
		default:
			break;
	}
	
	_validator.validations[@(indexPath.row)].uiComponent = cell.textField;
	cell.textField.tag = indexPath.row;
	
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
