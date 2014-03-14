//
//  CommentsViewController.h
//  Munchrs
//
//  Created by Triin Uudam on 3/27/13.
//  Copyright (c) 2013 Mobi Solutions OÜ. All rights reserved.
//

#import <Parse/Parse.h>

@class BaseStoryViewController;
@class CommentHeaderView;

@interface CommentsViewController : PFQueryTableViewController {
  PFObject *story_;
  BaseStoryViewController *baseViewController_;
  CommentHeaderView *commentCountView_;
  NSInteger commentCount_;
}
@property (nonatomic, strong) PFObject *story;
@property (nonatomic, strong) BaseStoryViewController *baseViewController;
@property (nonatomic, strong) CommentHeaderView *commentCountView;
@property (nonatomic, assign) NSInteger commentCount;

- (void)refreshComments;

@end
