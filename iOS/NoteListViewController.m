//  nvALT iOS — note list (iPhone/iPad primary column)

#import "NoteListViewController.h"
#import "NoteEditorViewController.h"
#import "NVNotesManager.h"
#import "NVNote.h"

static NSString *const kCellID = @"NoteCell";

@interface NoteListViewController ()
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) NSArray<NVNote *> *displayedNotes;
@end

@implementation NoteListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"nvALT";
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
    if (@available(iOS 11, *)) {
        self.navigationController.navigationBar.prefersLargeTitles = YES;
    }

    // Table view
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.dataSource = self;
    self.tableView.delegate   = self;
    self.tableView.rowHeight  = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 60;
    [self.view addSubview:self.tableView];

    // Search controller (acts as the nvALT-style unified search/create bar)
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.obscuresBackgroundDuringPresentation = NO;
    self.searchController.searchBar.placeholder = @"Search or create note…";
    self.searchController.searchBar.delegate = self;
    self.navigationItem.searchController = self.searchController;
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
    self.definesPresentationContext = YES;

    // New-note button
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
        target:self action:@selector(newNoteAction)];

    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(notesChanged:)
        name:NVNotesManagerDidChangeNotification object:nil];

    [self reloadData];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Data

- (void)reloadData {
    self.displayedNotes = [[NVNotesManager sharedManager] filteredNotes];
    [self.tableView reloadData];
}

- (void)notesChanged:(NSNotification *)note {
    [self reloadData];
}

#pragma mark - Actions

- (void)newNoteAction {
    NSString *seed = self.searchController.searchBar.text ?: @"";
    seed = [seed stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NVNote *note = [[NVNotesManager sharedManager] createNoteWithTitle:seed content:@""];
    [self openNote:note animated:YES];
}

- (void)openNote:(NVNote *)note animated:(BOOL)animated {
    NoteEditorViewController *editor = [[NoteEditorViewController alloc] init];
    editor.note = note;

    // iPad: push into detail column; iPhone: push onto stack
    if (self.splitViewController) {
        UINavigationController *detailNav = (UINavigationController *)self.splitViewController.viewControllers.lastObject;
        [detailNav setViewControllers:@[editor] animated:NO];
        [self.splitViewController showDetailViewController:detailNav sender:self];
    } else {
        [self.navigationController pushViewController:editor animated:animated];
    }
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    [NVNotesManager sharedManager].searchString = searchController.searchBar.text;
}

#pragma mark - UISearchBarDelegate

// Pressing Return in the search bar creates/selects the matching note (classic nvALT behaviour)
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    NSString *query = [searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (query.length == 0) return;

    // Exact title match → open it; otherwise create a new note
    NSArray *filtered = self.displayedNotes;
    NVNote *exact = nil;
    for (NVNote *n in filtered) {
        if ([n.title caseInsensitiveCompare:query] == NSOrderedSame) { exact = n; break; }
    }
    if (!exact && filtered.count == 1) exact = filtered.firstObject;

    if (exact) {
        [self openNote:exact animated:YES];
    } else {
        NVNote *note = [[NVNotesManager sharedManager] createNoteWithTitle:query content:@""];
        [self openNote:note animated:YES];
    }
    [searchBar resignFirstResponder];
    self.searchController.active = NO;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)self.displayedNotes.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kCellID];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.numberOfLines = 1;
        cell.detailTextLabel.numberOfLines = 2;
        cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
    }
    NVNote *note = self.displayedNotes[(NSUInteger)indexPath.row];
    cell.textLabel.text = [note titlePreview];
    cell.detailTextLabel.text = [note contentPreview];
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NVNote *note = self.displayedNotes[(NSUInteger)indexPath.row];
        [[NVNotesManager sharedManager] deleteNote:note];
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self openNote:self.displayedNotes[(NSUInteger)indexPath.row] animated:YES];
}

@end
