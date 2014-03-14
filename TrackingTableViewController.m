//
//  TrackingTableViewController.m
//  Fitness
//
//  Created by Triin Uudam on 24/04/14.
//  Copyright (c) 2014 Triin Uudam. All rights reserved.
//

#import "TrackingTableViewController.h"
#import "TrackingTableViewCell.h"
#import "UIView+Extensions.h"
#import "ProgressView.h"
#import "PauseView.h"
#import "LoginViewController.h"
#import "SignUpViewController.h"

#define kTagStartWorkout      0
#define kTagFinishWorkout     1
#define kHeightForHeader      51.0

@interface TrackingTableViewController () {
  
  NSIndexPath *expandableIndexPath_;
  ProgressView *progressView_;
  NSTimer *sessionTimer_;
  NSTimer *pauseTimer_;
  NSDate *timeStamp_;
  BOOL trackingActive_;
  PauseView *pauseView_;
  int pause_;
  int pauseCountDown_;
  NSMutableDictionary *tableViewCells_;
  BOOL pauseActive_;
}

@property (nonatomic) NSIndexPath *expandableIndexPath;
@property (nonatomic, strong) ProgressView *progressView;
@property (nonatomic, strong) NSTimer *sessionTimer;
@property (nonatomic, strong) NSTimer *pauseTimer;
@property (nonatomic, strong) NSDate *timeStamp;
@property (nonatomic, assign) BOOL trackingActive;
@property (nonatomic, strong) PauseView *pauseView;
@property (nonatomic, assign) int pause;
@property (nonatomic, assign) int pauseCountDown;
@property (nonatomic, strong) NSMutableDictionary *tableViewCells;

@end

@implementation TrackingTableViewController

@synthesize workout = workout_;
@synthesize expandableIndexPath = expandableIndexPath_;
@synthesize exercises = exercises_;
@synthesize progressView = progressView_;
@synthesize sessionTimer = sessionTimer_;
@synthesize pauseTimer = pauseTimer_;
@synthesize timeStamp = timeStamp_;
@synthesize trackingActive = trackingActive_;
@synthesize pauseView = pauseView_;
@synthesize pause = pause_;
@synthesize pauseCountDown = pauseCountDown_;
@synthesize tableViewCells = tableViewCells_;

- (id)init
{
  self = [super initWithNibName:@"TrackingTableViewController" bundle:nil];
  if (self) {
    return self;
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  [self.tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
  progressView_ = [[ProgressView alloc] init];
  self.navigationItem.titleView = [UILabel titleLabelWithText:[workout_ objectForKey:@"name"]];
//  [self.tableView setTableHeaderView:progressView_];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showPause) name:kSetCompleted object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopPause) name:kPauseCancelled object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateProgressView) name:kSetUpdated object:nil];
  if (![PFUser currentUser]) {
    [self showLoginView];
  }
  tableViewCells_ = [NSMutableDictionary dictionary];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  if ([PFUser currentUser]) {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"Start tracking?", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"Start", nil), nil];
    [alert setTag:kTagStartWorkout];
    [alert show];
  }
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}

- (void)dealloc
{
  [sessionTimer_ invalidate];
  [pauseTimer_ invalidate];
  [pauseView_ removeFromSuperview];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)showLoginView
{
  // Create the log in view controller
  LoginViewController *logInViewController = [[LoginViewController alloc] init];
  [logInViewController setDelegate:self]; // Set ourselves as the delegate
  [logInViewController setFields: PFLogInFieldsDefault | PFLogInFieldsFacebook | PFLogInFieldsDismissButton];
  // Create the sign up view controller
  SignUpViewController *signUpViewController = [[SignUpViewController alloc] init];
  [signUpViewController setDelegate:self]; // Set ourselves as the delegate
  
  // Assign our sign up controller to be displayed from the login controller
  [logInViewController setSignUpController:signUpViewController];
  
  // Present the log in view controller
  [self presentViewController:logInViewController animated:YES completion:NULL];
}

- (void)startTimer
{
  trackingActive_ = YES;
  timeStamp_ = [NSDate date];
  sessionTimer_ = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateTimer) userInfo:nil repeats:YES];
}

- (void)updateTimer
{
  NSTimeInterval progress = [[NSDate date] timeIntervalSinceDate:timeStamp_];
  double minutes = floor(progress/60);
  double seconds = trunc(progress - minutes * 60);
  double hours = trunc(progress / 3600.0);
  [progressView_ updateTimerLabelTo:[NSString stringWithFormat:@"%02.0f:%02.0f:%02.0f", hours, minutes, seconds]];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return exercises_.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  if ([expandableIndexPath_ isEqual:indexPath]) {
    return kExpandedCellHeight;
  }
  return kCollapsedCellHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  return progressView_;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  return kHeightForHeader;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *cellIdentifier = @"CellIdentifier";
  
  TrackingTableViewCell *cell= (TrackingTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
  
  if (cell == nil) {
    cell = (TrackingTableViewCell *)[TrackingTableViewCell loadViewFromXib:@"TrackingTableViewCell"];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
  }
  [cell setupWithExercise:[exercises_ objectAtIndex:indexPath.row]];
  [tableViewCells_ setObject:cell forKey:@(indexPath.row)];
  
    return cell;
}

 #pragma mark - Table view delegate
 
 // In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
 - (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
 {
   if ([expandableIndexPath_ isEqual:indexPath])
   {
     [self setExpandableIndexPath:nil];
   }
   else
   {
     [self setExpandableIndexPath:indexPath];
     [self.tableView scrollToNearestSelectedRowAtScrollPosition:UITableViewScrollPositionTop animated:YES];
   }
   [self.tableView beginUpdates];
   [self.tableView endUpdates];
   PFObject *exercise = [exercises_ objectAtIndex:indexPath.row];
   pause_ = [[exercise objectForKey:@"pause"] intValue];
 }


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
  if (alertView.tag == kTagFinishWorkout) {
    if (buttonIndex == 1) {
      [self finish];
    }
  }
  else if (alertView.tag == kTagStartWorkout) {
    if (buttonIndex == 1)
    {
      [self startWorkout];
    }
    else if (buttonIndex == 0 && [PFUser currentUser])
    {
      UIBarButtonItem *finish = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Start", nil) style:UIBarButtonItemStylePlain target:self action:@selector(startWorkout)];
      [self.navigationItem setRightBarButtonItem:finish];
    }
  }
}

- (void)startWorkout
{
  [self startTimer];
  UIBarButtonItem *finish = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Finish", nil) style:UIBarButtonItemStylePlain target:self action:@selector(finishWorkout)];
  [self.navigationItem setRightBarButtonItem:finish];
}

- (void)finishWorkout
{
  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Finish and save workout?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Save", nil];
  [alert setTag:kTagFinishWorkout];
  [alert show];
}

- (void)finish
{
  [sessionTimer_ invalidate];
  if (pauseActive_)
  {
    [self stopPause];
  }
  trackingActive_ = NO;
  
  PFObject *history = [PFObject objectWithClassName:@"History"];
  //add sets, time
  [history setObject:[NSDate date] forKey:@"date"];
  [history setObject:[workout_ objectForKey:@"name"] forKey:@"workoutName"];
  [history setObject:[workout_ objectForKey:@"planName"] forKey:@"planName"];
  NSMutableString *setsName = [NSMutableString string];
  NSMutableString *setsReps = [NSMutableString string];
  NSMutableString *setsWeight = [NSMutableString string];
  
  for (TrackingTableViewCell *cell in [self tableViewCells]) {
    [setsName appendString:[NSString stringWithFormat:@"%@;",[cell setName]]];
    [setsReps appendString:[NSString stringWithFormat:@"%@;",[cell reps]]];
    [setsWeight appendString:[NSString stringWithFormat:@"%@;",[cell weight]]];
  }
  
  [history setObject:setsName forKey:@"setsName"];
  [history setObject:setsReps forKey:@"setsReps"];
  [history setObject:setsWeight forKey:@"setsWeight"];
  [history setObject:[progressView_ currentTime] forKey:@"time"];
  [history saveInBackground];
}

- (void)updateProgressView
{
  int selected = 0;
  int total = 0;
  for (int i = 0; i < exercises_.count; i++) {
    TrackingTableViewCell *cell = [tableViewCells_ objectForKey:@(i)];
    selected += [cell selectedSetsCount];
    total += [cell setArray].count;
  }
  [progressView_ updateProgressTo:((float)selected/(float)total)];
}

- (void)showPause
{
  if (pauseActive_) {
    [self stopPause];
  }
  if (trackingActive_) {
    if (!pauseView_) {
      pauseView_ = [[PauseView alloc] init];
      CGRect newFrame = pauseView_.frame;
      newFrame.origin = CGPointMake(self.view.frame.size.width / 2 - newFrame.size.width / 2, self.view.frame.size.height / 2 - newFrame.size.height);
      pauseView_.frame = newFrame;
    }
    pauseCountDown_ = pause_;
    [self updatePauseProgress];
    [self.view addSubview:pauseView_];
    pauseTimer_ = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updatePauseProgress) userInfo:nil repeats:YES];
    pauseActive_ = YES;
  }
  [self updateProgressView];
}

- (void)updatePauseProgress
{
  double minutes = floor(pauseCountDown_/60);
  double seconds = trunc(pauseCountDown_ - minutes * 60);
  [pauseView_ updateTimerLabelTo:[NSString stringWithFormat:@"%02.0f:%02.0f", minutes, seconds]];
  pauseCountDown_ -= 1;
  if (pauseCountDown_ == 0) {
    [self stopPause];
  }
}

- (void)stopPause
{
  [pauseTimer_ invalidate];
  [pauseView_ removeFromSuperview];
  double minutes = floor(pause_/60);
  double seconds = trunc(pause_ - minutes * 60);
  [pauseView_ updateTimerLabelTo:[NSString stringWithFormat:@"%02.0f:%02.0f", minutes, seconds]];
  TrackingTableViewCell *cell = (TrackingTableViewCell *)[self.tableView cellForRowAtIndexPath:expandableIndexPath_];
  [cell selectNextSet];
  pauseActive_ = NO;
}

// Sent to the delegate to determine whether the log in request should be submitted to the server.
- (BOOL)logInViewController:(PFLogInViewController *)logInController shouldBeginLogInWithUsername:(NSString *)username password:(NSString *)password {
  // Check if both fields are completed
  if (username && password && username.length != 0 && password.length != 0) {
    return YES; // Begin login process
  }
  
  [[[UIAlertView alloc] initWithTitle:@"Missing Information"
                              message:@"Make sure you fill out all of the information!"
                             delegate:nil
                    cancelButtonTitle:@"ok"
                    otherButtonTitles:nil] show];
  return NO; // Interrupt login process
}

// Sent to the delegate when a PFUser is logged in.
- (void)logInViewController:(PFLogInViewController *)logInController didLogInUser:(PFUser *)user {
  [self dismissViewControllerAnimated:YES completion:NULL];
}

// Sent to the delegate when the log in attempt fails.
- (void)logInViewController:(PFLogInViewController *)logInController didFailToLogInWithError:(NSError *)error {
  NSLog(@"Failed to log in... %@", error);
}

// Sent to the delegate when the log in screen is dismissed.
- (void)logInViewControllerDidCancelLogIn:(PFLogInViewController *)logInController {
  [self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)signUpViewController:(PFSignUpViewController *)signUpController shouldBeginSignUp:(NSDictionary *)info {
  BOOL informationComplete = YES;
  
  // loop through all of the submitted data
  for (id key in info) {
    NSString *field = [info objectForKey:key];
    if (!field || field.length == 0) { // check completion
      informationComplete = NO;
      break;
    }
  }
  
  // Display an alert if a field wasn't completed
  if (!informationComplete) {
    [[[UIAlertView alloc] initWithTitle:@"Missing Information"
                                message:@"Make sure you fill out all of the information!"
                               delegate:nil
                      cancelButtonTitle:@"ok"
                      otherButtonTitles:nil] show];
  }
  
  return informationComplete;
}

// Sent to the delegate when a PFUser is signed up.
- (void)signUpViewController:(PFSignUpViewController *)signUpController didSignUpUser:(PFUser *)user {
  [self dismissViewControllerAnimated:YES completion:nil]; // Dismiss the PFSignUpViewController
  [[[UIAlertView alloc] initWithTitle:nil
                              message:@"Welcome to Track!"
                             delegate:nil
                    cancelButtonTitle:@"Yay!"
                    otherButtonTitles:nil] show];
}

// Sent to the delegate when the sign up attempt fails.
- (void)signUpViewController:(PFSignUpViewController *)signUpController didFailToSignUpWithError:(NSError *)error {
  NSLog(@"Failed to sign up...");
}

// Sent to the delegate when the sign up screen is dismissed.
- (void)signUpViewControllerDidCancelSignUp:(PFSignUpViewController *)signUpController {
  NSLog(@"User dismissed the signUpViewController");
}

@end
