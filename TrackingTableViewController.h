//
//  TrackingTableViewController.h
//  Fitness
//
//  Created by Triin Uudam on 24/04/14.
//  Copyright (c) 2014 Triin Uudam. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TrackingTableViewController : UITableViewController <PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate>
{
  PFObject *workout_;
  NSArray *exercises_;
}

@property (nonatomic, strong) PFObject *workout;
@property (nonatomic, strong) NSArray *exercises;

@end
