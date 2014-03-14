//
//  SavedSearchesViewController.h
//  DragonFly
//
//  Created by Triin Uudam on 3/15/12.
//  Copyright (c) 2012 Mobi Solutions OÜ. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "SavedSearchesRequest.h"
#import "ProductsListViewController.h"

@class Database;
@class NetworkRequest;
@class NSFetchedResultsController;

@interface SavedSearchesViewController : UITableViewController <SavedSearchesRequestDelegate, NSFetchedResultsControllerDelegate, ProductListRefreshDelegate> {
 @private
  Database *database_;
  NetworkRequest *executedRequest_;
  NSFetchedResultsController *searches_;
}

@property (nonatomic, strong) Database *database;
@property (nonatomic, strong) NSFetchedResultsController *searches;
@property (nonatomic, strong) NetworkRequest *executedRequest;

@end
