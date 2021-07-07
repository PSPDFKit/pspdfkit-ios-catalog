//
//  Copyright © 2011-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

#import "PSCSplitDocumentSelectorController.h"
#import "PSCSplitPDFViewController.h"

@implementation PSCSplitDocumentSelectorController

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.clearsSelectionOnViewWillAppear = NO;
    self.preferredContentSize = CGSizeMake(320.0, 600.0);

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cycle" style:UIBarButtonItemStylePlain target:self action:@selector(cycleAction)];

    //self.navigationItem.leftBarButtonItems = @[[[UIBarButtonItem alloc] initWithTitle:@"Deselect" style:UIBarButtonItemStylePlain target:self action:@selector(deselectAction)]];
}

#pragma mark - Private

// tests fast cycling through the pdf elements
- (void)cycleAction {
    [PSPDFKitGlobal.sharedInstance.cache clearCache];

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        for (NSInteger sectionIndex = 0; sectionIndex < [self numberOfSectionsInTableView:self.tableView]; sectionIndex++) {
            for (NSInteger rowIndex = 0; rowIndex < [self tableView:self.tableView numberOfRowsInSection:sectionIndex]; rowIndex++) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
                    [self.tableView selectRowAtIndexPath:selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
                    [self tableView:self.tableView didSelectRowAtIndexPath:selectedIndexPath];
                });
                [NSThread sleepForTimeInterval:0.05 * arc4random_uniform(5)];
            }
        }
    });
}

- (void)deselectAction {
    NSIndexPath *indexPathForSelectedRow = self.tableView.indexPathForSelectedRow;
    if (indexPathForSelectedRow) {
        [self.tableView deselectRowAtIndexPath:indexPathForSelectedRow animated:YES];
    }
    [self.masterController displayDocument:nil pageIndex:0];
}

@end
