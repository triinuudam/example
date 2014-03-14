//
//  CommentsViewController.m
//  Munchrs
//
//  Created by Triin Uudam on 3/27/13.
//  Copyright (c) 2013 Mobi Solutions OÜ. All rights reserved.
//

#import "CommentsViewController.h"
#import "CommentCell.h"
#import "UIView + Extensions.h"
#import "BaseStoryViewController.h"
#import "UIImageView+Extentions.h"
#import "CommentHeaderView.h"
#import "Crittercism.h"

@interface CommentsViewController () {
  NSMutableDictionary *cellDictionary_;
}

@property (nonatomic, strong) NSMutableDictionary *cellDictionary;

@end

@implementation CommentsViewController

@synthesize story = story_;
@synthesize baseViewController = baseViewController_;
@synthesize cellDictionary = cellDictionary_;
@synthesize commentCountView = commentCountView_;
@synthesize commentCount = commentCount_;

- (id)init
{
  self = [super init];
  if (self) {
    self.className = @"Comment";
    self.pullToRefreshEnabled = NO;
    self.paginationEnabled = NO;
    self.loadingViewEnabled = NO;
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  [self setCellDictionary:[NSMutableDictionary dictionary]];
  
  [self.tableView setSeparatorColor:[UIColor clearColor]];
  [self.tableView setBackgroundColor:[UIColor clearColor]];
  UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.tableView.frame];
  [imageView setStretchableBackgroundImageName:@"story-bg.png" withEdgeInset:30.0];
  [self.tableView setBackgroundView:imageView];
  
  CommentHeaderView *headerView = [[CommentHeaderView alloc] initWithStory:story_ commentCount:commentCount_];
  [self setCommentCountView:headerView];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  
  MSLog(@"didReceiveMemoryWarning");
}

- (PFQuery *)queryForTable
{
  [Crittercism leaveBreadcrumb:@"Comments view table query"];
  PFQuery *query = [PFQuery queryWithClassName:self.className];
  [query whereKey:@"storyId" equalTo:story_.objectId];
  query.cachePolicy = kPFCachePolicyCacheThenNetwork;
  [query orderByAscending:@"createdAt"];
  return query;
}

- (void)objectsDidLoad:(NSError *)error
{
  [super objectsDidLoad:error];
  if (!error) {
    [baseViewController_ updatesFinishedFor:self];
  }
}

- (void)objectsWillLoad {
  [super objectsWillLoad];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
  CGFloat height = commentCountView_.frame.size.height;
  if (self.objects.count == 0) {
    height = 0.0;
  }
  return height;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
  [commentCountView_ refresh];
  
  return commentCountView_;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  PFObject *comment = [self objectAtIndexPath:indexPath];
  CommentCell *commentCell = [cellDictionary_ objectForKey:comment.objectId];
  if (!commentCell) {
    commentCell = (CommentCell *)[CommentCell loadViewFromXib:@"CommentCell"];
    [commentCell configureWithComment:comment];
    [cellDictionary_ setObject:commentCell forKey:comment.objectId];
  }
  return commentCell.frame.size.height;
  
}

- (PFTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object
{
  [super tableView:tableView cellForRowAtIndexPath:indexPath object:object];
  CommentCell *cell = [cellDictionary_ objectForKey:object.objectId];
  
  if (cell == nil) {
    cell = (CommentCell *)[CommentCell loadViewFromXib:@"CommentCell"];
    [cell configureWithComment:object];
    [cellDictionary_ setObject:cell forKey:object.objectId];
  }
  
  return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
  if(indexPath.row == [self.objects count])
  {
    return NO;
  }
  
  PFObject *comment = [self objectAtIndexPath:indexPath];
  if ([[comment objectForKey:@"userId"] isEqualToString:[PFUser currentUser].objectId]) {
    return YES;
  }
  
  return NO;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
  return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    PFObject *comment = [self objectAtIndexPath:indexPath];
    [comment deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
      if (!error) {
        [self loadObjects];
        [baseViewController_ updateCommentLikeCountValues];
      }
    }];
  }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (void)refreshComments
{
  [self loadObjects];
}

@end
