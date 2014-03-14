//
//  SavedSearchesViewController.m
//  DragonFly
//
//  Created by Triin Uudam on 3/15/12.
//  Copyright (c) 2012 Mobi Solutions OÜ. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "SavedSearchesViewController.h"
#import "Database.h"
#import "NetworkRequest.h"
#import "SavedSearch.h"
#import "Constants.h"
#import "MBProgressHUD.h"
#import "Database+SavedSearches.h"
#import "ProductsListViewController.h"
#import "ProductListBySavedSearchRequest.h"
#import "FilterConfiguration.h"
#import "UITableViewCell+Extensions.h"
#import "Database+Products.h"

@interface SavedSearchesViewController ()

@end

@implementation SavedSearchesViewController
@synthesize database = database_;
@synthesize searches = searches_;
@synthesize executedRequest = executedRequest_;


- (id)init {
  self = [super initWithNibName:@"SavedSearchesViewController" bundle:nil];
  if (self) {
    // Custom initialization
  }
  return self;
}

- (void)dealloc {
  [searches_ setDelegate:nil];
  [executedRequest_ clearDelegatesAndCancel];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)viewDidLoad {
  [super viewDidLoad];
[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetFetchedController) name:kNotificationLoggedOut object:nil];
}

- (void)viewDidUnload {
  [super viewDidUnload];
  // Release any retained subviews of the main view.
  // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self.navigationItem setTitle:NSLocalizedString(@"saved.searches.view.controller.title", nil)];

  if (searches_ == nil) {
    NSFetchedResultsController *controller = [database_ fetchedControllerForSavedSearches];
    [self setSearches:controller];

    [searches_ setDelegate:self];

    NSError *error = nil;
    [searches_ performFetch:&error];
    if (error != nil) {
      MSLog(@"fetch error %@", error.description);
    }
    [self.tableView reloadData];
  }

  SavedSearchesRequest *request = [[SavedSearchesRequest alloc] initRequest];
  [request setRequestDelegate:self];
  [request setDatabase:database_];
  [self setExecutedRequest:request];
  [request startAsynchronous];
  [MBProgressHUD showHUDAddedTo:self.tableView animated:TRUE];
  if ([[searches_ fetchedObjects] count] == 0) {
    [UITableViewCell showNoItemsCellOnView:self.view hasHeader:NO hasSearch:NO];
  }
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
  [MBProgressHUD hideHUDForView:self.tableView animated:TRUE];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return [[searches_ sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  id <NSFetchedResultsSectionInfo> sectionInfo = [[searches_ sections] objectAtIndex:section];
  return [sectionInfo numberOfObjects];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
  UIView *footer = [[UIView alloc] initWithFrame:CGRectZero];
  return footer;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *CellIdentifier = @"Cell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
  }
  SavedSearch *search = [searches_ objectAtIndexPath:indexPath];
  [cell.textLabel setText:search.name];
  [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];

  return cell;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
  [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
  if ([[searches_ fetchedObjects] count] > 0) {
    [UITableViewCell removeNoItemsCellFromView:self.view];
  }
  UITableView *tableView = self.tableView;
  switch (type) {

    case NSFetchedResultsChangeInsert:
      [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
      break;
    case NSFetchedResultsChangeUpdate:
      [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
      break;
    case NSFetchedResultsChangeDelete:
      [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
      break;
    case NSFetchedResultsChangeMove:
      [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
      [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
      break;
  }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
  [self.tableView endUpdates];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:TRUE];

  [self.navigationItem setTitle:NSLocalizedString(@"button.title.back", nil)];

  SavedSearch *clickedOn = [searches_ objectAtIndexPath:indexPath];

  ProductsListViewController *productsListViewController = [[ProductsListViewController alloc] init];
  [productsListViewController setDatabase:database_];
  [productsListViewController setIndexPath:indexPath];
  [productsListViewController setDelegate:self];
  [productsListViewController setDisplayTitle:clickedOn.name];
  [productsListViewController setSavedSearches:YES];

  NSFetchedResultsController *fetchedResultsController = [database_ fetchedControllerForProductsInSavedSearch:clickedOn];
  [productsListViewController setContentController:fetchedResultsController];

  [self.navigationController pushViewController:productsListViewController animated:TRUE];
}

- (void)savedSearchesReceived {
  [MBProgressHUD hideHUDForView:self.tableView animated:TRUE];
}

- (void)savedSearchesRequestError:(NSString *)message {
  [MBProgressHUD hideHUDForView:self.tableView animated:TRUE];
  UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"saved.searches.controller.error.title", nil)
                                                      message:message
                                                     delegate:nil cancelButtonTitle:NSLocalizedString(@"button.title.OK", nil) otherButtonTitles:nil];
  [alertView show];
}

- (NetworkRequest *)refreshRequestForIndexPath:(NSIndexPath *)indexPath withFilter:(FilterConfiguration *)filterConfiguration pageNr:(int)pageNr {
  SavedSearch *refreshFor = [searches_ objectAtIndexPath:indexPath];
  ProductListBySavedSearchRequest *request = [[ProductListBySavedSearchRequest alloc] initWithSavedSearch:refreshFor];
  [request setDatabase:database_];
  return request;
}

- (void)resetFetchedController {
  searches_ = nil;
}


@end
