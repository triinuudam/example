//
//  Database+Categories.m
//  DragonFly
//
//  Created by Triin Uudam on 3/23/12.
//  Copyright (c) 2012 Mobi Solutions OÜ. All rights reserved.
//

#import "Database+Categories.h"
#import "ProductCategory.h"
#import "Constants.h"

@implementation Database (Categories)

- (ProductCategory *)findOrCreateCategoryWithId:(NSString *)categoryID {
  
  ProductCategory *category = [ProductCategory insertInManagedObjectContext:[self managedObjectContext]];
  [category setCategoryId:categoryID];
  
  if (category == nil) {
   
  }
  return category;
}

- (ProductCategory *)categoryWithId:(NSString *)categoryId {
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"categoryId = %@", categoryId];
  return [self findCoreDataObjectNamed:@"ProductCategory" withPredicate:predicate];
}

- (int)itemsCountForCategory:(ProductCategory *)category {
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"category = %@", category];
  return [[self listCoreObjectsNamed:@"Product" withPredicate:predicate] count];
}

- (NSArray *)subCategoriesForParent:(ProductCategory *)category {
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"parentCategoryId = %@", category.categoryId];
  return [self listCoreObjectsNamed:@"ProductCategory" withPredicate:predicate];
}

- (NSFetchedResultsController *)fetchedResultsControllerForCategories {
  NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
  NSEntityDescription *entity = [NSEntityDescription entityForName:@"ProductCategory" inManagedObjectContext:self.managedObjectContext];
  [fetchRequest setEntity:entity];
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"categoryLevel = 2"];
  [fetchRequest setPredicate:predicate];
  NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"orderNo" ascending:YES];
  [fetchRequest setSortDescriptors:[NSArray arrayWithObject:descriptor]];
  NSFetchedResultsController *controller = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest 
                                                                               managedObjectContext:self.managedObjectContext 
                                                                                 sectionNameKeyPath:nil 
                                                                                          cacheName:nil];
  return controller;
}

- (NSFetchedResultsController *)fetchedResultsControllerForProductsWithCategory:(ProductCategory *)category {
  NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
  NSEntityDescription *entity = [NSEntityDescription entityForName:@"Product" inManagedObjectContext:self.managedObjectContext];
  [fetchRequest setEntity:entity];
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"category = %@", category];
  [fetchRequest setPredicate:predicate];
  NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"price" ascending:YES];
  [fetchRequest setSortDescriptors:[NSArray arrayWithObject:descriptor]];
  NSFetchedResultsController *controller = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest 
                                                                               managedObjectContext:self.managedObjectContext 
                                                                                 sectionNameKeyPath:nil 
                                                                                          cacheName:nil];
  return controller;
}

- (NSFetchedResultsController *)fetchedResultsControllerForCategoriesWithParentCategory:(ProductCategory *)parentCategory {
  NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
  NSEntityDescription *entity = [NSEntityDescription entityForName:@"ProductCategory" inManagedObjectContext:self.managedObjectContext];
  [fetchRequest setEntity:entity];
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"parentCategoryId = %@", parentCategory.categoryId];
  [fetchRequest setPredicate:predicate];
  NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"orderNo" ascending:YES];
  [fetchRequest setSortDescriptors:[NSArray arrayWithObject:descriptor]];
  NSFetchedResultsController *controller = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest 
                                                                               managedObjectContext:self.managedObjectContext 
                                                                                 sectionNameKeyPath:nil 
                                                                                          cacheName:nil];
  return controller;

}

- (void)deleteAllCategories {

  NSArray *categories = [self listCoreObjectsNamed:@"ProductCategory"];
  for (ProductCategory *category in categories) {
    [self deleteObject:category saveAfter:NO];
  }
  [self saveContext];
}

@end
