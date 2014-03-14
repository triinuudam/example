//
//  24hSearchViewController.m
//  SunnyChairs
//
//  Created by Triin Uudam on 26/05/14.
//  Copyright (c) 2014 Triin Uudam. All rights reserved.
//

#import "SunnySearchViewController.h"
#import "Place.h"
#import "SearchResultTableViewCell.h"
#import "PlaceDetailsViewController.h"

#define kDistanceFilter       100
#define kHeaderHeight         22.0
#define kHeightForRow         28.0

@interface SunnySearchViewController ()
{
  UITableView *tableView_;
  CLLocationManager *locationManager_;
  CLLocation *currentLocation_;
  int area_;
}

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLLocation *currentLocation;
@property (nonatomic, assign) int area;

- (IBAction)back:(id)sender;

@end

@implementation SunnySearchViewController

@synthesize tableView = tableView_;
@synthesize locationManager = locationManager_;
@synthesize currentLocation = currentLocation_;
@synthesize places = places_;
@synthesize area = area_;

- (id)initWithArea:(int)area
{
  self = [super init];
  if (self) {
    area_ = area;
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  [self setupPlaces];
  locationManager_ = [CLLocationManager new];
  locationManager_.delegate = self;
  locationManager_.distanceFilter = kDistanceFilter;
  locationManager_.desiredAccuracy = kCLLocationAccuracyBest;
  [locationManager_ startUpdatingLocation];
  self.tableView.separatorColor = [UIColor clearColor];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusDenied && !currentLocation_) {
    [locationManager_ startUpdatingLocation];
  }
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)setupPlaces
{
  NSMutableDictionary *dict = [NSMutableDictionary dictionary];
  NSPredicate *morningPredicate = [NSPredicate predicateWithFormat:@"area = %d && dailySunny CONTAINS[cd] %@", area_, @"matin"];
  NSArray *morningPlaces = [Place MR_findAllWithPredicate:morningPredicate];
  [dict setObject:morningPlaces forKey:@(0)];
  
  NSPredicate *afternoonPredicate = [NSPredicate predicateWithFormat:@"area = %d && dailySunny CONTAINS[cd] %@", area_, @"midi"];
  NSArray *afternoonPlaces = [Place MR_findAllWithPredicate:afternoonPredicate];
  [dict setObject:afternoonPlaces forKey:@(1)];
  
  NSPredicate *eveningPredicate = [NSPredicate predicateWithFormat:@"area = %d && dailySunny CONTAINS[cd] %@", area_, @"soir"];
  NSArray *eveningPlaces = [Place MR_findAllWithPredicate:eveningPredicate];
  [dict setObject:eveningPlaces forKey:@(2)];
  
  
  [self setPlaces:dict];
  MSLog(@"dictionary %@", dict);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return places_.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  NSArray *arr = [places_ objectForKey:@(section)];
  return arr.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
  if (section >= 0 && section <= 2) {
    return kHeaderHeight;
  }
  return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
  if (section == 0) {
    return [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"morning_24"]];
  }
  else if (section == 1) {
    return [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"afternoon_24"]];
  }
  else if (section == 2) {
    return [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"evening_24"]];
  }
  return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  return kHeightForRow;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *cellIdentifier = @"CellIdentifier";
  
  SearchResultTableViewCell *cell = (SearchResultTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
  
  if (cell == nil)
  {
    cell = [(SearchResultTableViewCell *)[SearchResultTableViewCell alloc] initForSunnyResults];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
  }
  NSArray *section = [places_ objectForKey:@(indexPath.section)];
  Place *place = [section objectAtIndex:indexPath.row];
  [cell setupWithPlace:place currentLocation:currentLocation_];
  if (indexPath.row != section.count - 1) {
    UIImageView *line = [[UIImageView alloc] initWithFrame:CGRectMake(10, 28, 300, 1)];
    line.backgroundColor = [UIColor whiteColor];
    [cell addSubview:line];
  }
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
  NSArray *section = [places_ objectForKey:@(indexPath.section)];
  Place *place = [section objectAtIndex:indexPath.row];
  [self openDetailsForPlace:place];
}

- (void)openDetailsForPlace:(Place *)place
{
  PlaceDetailsViewController *controller = [[PlaceDetailsViewController alloc] init];
  [controller setPlace:place];
  [self.navigationController pushViewController:controller animated:YES];
}

- (IBAction)back:(id)sender
{
  [self.navigationController popViewControllerAnimated:YES];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
  currentLocation_ = [locations lastObject];
  [locationManager_ stopUpdatingLocation];
  for (int i = 0; i < 3; i++) {
    NSArray *arr = [places_ objectForKey:@(i)];
    [self sortArrayByDistance:arr];
  }
  [self.tableView reloadData];
}

- (void)sortArrayByDistance:(NSArray *)sortArray
{
  sortArray = [sortArray sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
    Place *place1 = obj1;
    Place *place2 = obj2;
    
    CLLocation *placeLocation1 = [[CLLocation alloc] initWithLatitude:place1.latitudeValue longitude:place1.longitudeValue];
    CLLocationDistance distance1 = [currentLocation_ distanceFromLocation:placeLocation1];
    
    CLLocation *placeLocation2 = [[CLLocation alloc] initWithLatitude:place2.latitudeValue longitude:place2.longitudeValue];
    CLLocationDistance distance2 = [currentLocation_ distanceFromLocation:placeLocation2];
    
    if ( distance1 < distance2 ) {
      return (NSComparisonResult)NSOrderedAscending;
    } else if ( distance1 > distance2) {
      return (NSComparisonResult)NSOrderedDescending;
    } else {
      return (NSComparisonResult)NSOrderedSame;
    }
  }];
}

@end
