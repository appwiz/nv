//  nvALT iOS — note editor

#import "NoteEditorViewController.h"
#import "NVNote.h"
#import "NVNotesManager.h"

@interface NoteEditorViewController ()
@property (nonatomic, strong) UITextField *titleField;
@property (nonatomic, strong) UITextView  *contentView;
@property (nonatomic, strong) UILabel     *statusLabel;
@end

@implementation NoteEditorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    [self buildUI];
    [self populateFields];
    [self registerKeyboardNotifications];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemAction
        target:self action:@selector(shareNote)];
}

- (void)buildUI {
    // Title field
    self.titleField = [[UITextField alloc] init];
    self.titleField.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleField.placeholder = @"Title";
    self.titleField.font = [UIFont boldSystemFontOfSize:18];
    self.titleField.borderStyle = UITextBorderStyleNone;
    self.titleField.returnKeyType = UIReturnKeyNext;
    self.titleField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [self.titleField addTarget:self action:@selector(titleEdited) forControlEvents:UIControlEventEditingChanged];
    [self.view addSubview:self.titleField];

    // Horizontal rule
    UIView *rule = [[UIView alloc] init];
    rule.translatesAutoresizingMaskIntoConstraints = NO;
    rule.backgroundColor = [UIColor separatorColor];
    [self.view addSubview:rule];

    // Content text view
    self.contentView = [[UITextView alloc] init];
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentView.font = [UIFont systemFontOfSize:16];
    self.contentView.textContainerInset = UIEdgeInsetsMake(8, 8, 8, 8);
    self.contentView.delegate = self;
    [self.view addSubview:self.contentView];

    // Word/char count status bar
    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.statusLabel.font = [UIFont systemFontOfSize:11];
    self.statusLabel.textColor = [UIColor secondaryLabelColor];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.statusLabel];

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.titleField.topAnchor constraintEqualToAnchor:safe.topAnchor constant:10],
        [self.titleField.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:16],
        [self.titleField.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-16],
        [self.titleField.heightAnchor constraintEqualToConstant:44],

        [rule.topAnchor constraintEqualToAnchor:self.titleField.bottomAnchor constant:4],
        [rule.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [rule.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [rule.heightAnchor constraintEqualToConstant:0.5],

        [self.contentView.topAnchor constraintEqualToAnchor:rule.bottomAnchor],
        [self.contentView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.contentView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.contentView.bottomAnchor constraintEqualToAnchor:self.statusLabel.topAnchor],

        [self.statusLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.statusLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.statusLabel.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor],
        [self.statusLabel.heightAnchor constraintEqualToConstant:24],
    ]];
}

- (void)populateFields {
    if (!self.note) {
        self.title = @"nvALT";
        self.titleField.text = @"";
        self.contentView.text = @"";
        self.statusLabel.text = @"";
        return;
    }
    self.titleField.text = self.note.title;
    self.contentView.text = self.note.content;
    self.title = [self.note titlePreview];
    [self updateStatus];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.note && self.note.title.length == 0) {
        [self.titleField becomeFirstResponder];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self persistNote];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Note I/O

- (void)titleEdited {
    self.title = self.titleField.text.length > 0 ? self.titleField.text : @"New Note";
}

- (void)persistNote {
    if (!self.note) return;
    NSString *rawTitle = [self.titleField.text
        stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *rawContent = self.contentView.text;

    // If both are blank, delete the note
    if (rawTitle.length == 0 && rawContent.length == 0) {
        [[NVNotesManager sharedManager] deleteNote:self.note];
        return;
    }
    // Derive title from first line of content if title is empty
    if (rawTitle.length == 0) {
        NSString *firstLine = [rawContent componentsSeparatedByString:@"\n"].firstObject;
        rawTitle = firstLine.length > 60 ? [firstLine substringToIndex:60] : firstLine;
    }
    [[NVNotesManager sharedManager] updateNote:self.note title:rawTitle content:rawContent];
}

#pragma mark - Status

- (void)updateStatus {
    NSString *text = self.contentView.text ?: @"";
    NSArray *words = [text componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSUInteger wordCount = [[words filteredArrayUsingPredicate:
        [NSPredicate predicateWithFormat:@"length > 0"]] count];
    self.statusLabel.text = [NSString stringWithFormat:@"%lu words · %lu chars",
        (unsigned long)wordCount, (unsigned long)text.length];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    [self updateStatus];
}

#pragma mark - Share

- (void)shareNote {
    if (!self.note) return;
    NSString *text = [NSString stringWithFormat:@"%@\n\n%@",
        self.note.title, self.note.content];
    UIActivityViewController *av = [[UIActivityViewController alloc]
        initWithActivityItems:@[text] applicationActivities:nil];
    av.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItem;
    [self presentViewController:av animated:YES completion:nil];
}

#pragma mark - Keyboard

- (void)registerKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(keyboardChanged:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(keyboardChanged:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardChanged:(NSNotification *)notification {
    NSDictionary *info = notification.userInfo;
    CGRect endFrame = [info[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = (UIViewAnimationCurve)[info[UIKeyboardAnimationCurveUserInfoKey] integerValue];

    BOOL showing = [notification.name isEqualToString:UIKeyboardWillShowNotification];
    CGFloat keyboardHeight = showing ? CGRectGetHeight(endFrame) : 0;

    UIEdgeInsets insets = UIEdgeInsetsMake(0, 0, keyboardHeight, 0);
    [UIView animateWithDuration:duration delay:0
        options:(UIViewAnimationOptions)(curve << 16)
        animations:^{
            self.contentView.contentInset = insets;
            self.contentView.scrollIndicatorInsets = insets;
        } completion:nil];
}

@end
