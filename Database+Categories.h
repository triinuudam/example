//
//  Database+Categories.h
//  DragonFly
//
//  Created by Triin Uudam on 3/23/12.
//  Copyright (c) 2012 Mobi Solutions OÜ. All rights reserved.
//

#import "Database.h"

@class ProductCategory;
@interface Database (Categories)

- (ProductCategory *)findOrCreateCategoryWithId:(NSString *)categoryID;

- (ProductCategory *)categoryWithId:(NSString *)categoryId;

- (NSFetchedResultsController *)fetchedResultsControllerForCategories;

- (NSFetchedResultsController *)fetchedResultsControllerForProductsWithCategory:(ProductCategory *)category;

- (NSFetchedResultsController *)fetchedResultsControllerForCategoriesWithParentCategory:(ProductCategory *)parentCategory;

- (int)itemsCountForCategory:(ProductCategory *)category;

- (NSArray *)subCategoriesForParent:(ProductCategory *)category;

- (void)deleteAllCategories;

@end
