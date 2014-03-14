//
//  24hSearchViewController.h
//  SunnyChairs
//
//  Created by Triin Uudam on 26/05/14.
//  Copyright (c) 2014 Triin Uudam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface SunnySearchViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate>
{
  NSDictionary *places_;
}

@property (nonatomic, strong) NSDictionary *places;

- (id)initWithArea:(int)area;

@end
