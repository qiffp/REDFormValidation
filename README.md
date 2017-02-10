# REDFormValidation

An iOS form validation framework written in Objective-C.

## Example

### Setting up the form controller

```objc
typedef NS_ENUM(NSUInteger, FormCell) {
    FormCellFirstName,
    FormCellLastName,
    FormCellEmail,
    FormCellAddress,
    FormCellNote
};
...
@interface FormViewController : UIViewController <REDValidatorDelegate>
...
@property (nonatomic, strong) REDValidator *validator;
```

### Responding to validator delegate method calls

```objc
@implementation FormViewController
...
- (void)validator:(REDValidator *)validator didValidateFormWithResult:(REDValidationResult)result
{
    // Configure controller / view based on entire form result
}

- (void)validator:(REDValidator *)validator didValidateUIComponent:(NSObject<REDValidatableComponent> *)uiComponent result:(REDValidationResult)result error:(NSError *)error
{
    // Configure individual components (view, cell, etc.) based on their results
}
```

```objc
@implementation FormCell
...
- (void)validator:(REDValidator *)validator didValidateUIComponentWithResult:(REDValidationResult)result error:(NSError *)error
{
    // Configure all components of the class based on a result
}
```

### Creating the validator

```objc
@implementation FormViewController
...
_validator = [REDValidator new];
_validator.delegate = self;
_validator.networkInputDelay = 0.5;
```

### Adding a client-side validation

```objc
[_validator addValidation:
    [REDValidation validationWithIdentifier:@(FormCellFirstName)
                                       rule:[REDValidationRule ruleWithBlock:^BOOL(NSString *text) {
                                           // The type signature of the block has the component value as an id.
                                           // It can be treated as the value's actual type to avoid casting in the block.
                                           return text.length > 0;
                                       }]
    ]
];
```

### Adding a network validation

```objc
[_validator addValidation:
    [REDValidation validationWithIdentifier:@(FormCellEmail)
                                       rule:[REDNetworkValidationRule ruleWithBlock:^NSURLSessionTask *(id value, REDNetworkValidationRuleResultBlock completion) {
                                           NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:@"https://www.github.com/qiffp"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                               BOOL result = /* perform operation on response and/or component value */
                                               completion(result, error);
                                           }];
                                           [task resume];
                                           return task;
                                       }]
    ]
];
```

### Assigning the UI components

```objc
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = ...
...
    _validator.validations[@(indexPath.row)].uiComponent = cell.textField;
}
```

### Creating the form validation logic

```objc
// equivalent to ((FormCellFirstName && FormCellLastName) || FormCellEmail) && FormCellAddress
_validator.validationTree = [REDValidationTree and:@[
    [REDValidationTree or:@[
        [REDValidationTree and:@[@(FormCellFirstName), @(FormCellLastName)]],
        [REDValidationTree single:@(FormCellEmail)]
    ]],
    [REDValidationTree single:@(FormCellAddress)]
]];
```

