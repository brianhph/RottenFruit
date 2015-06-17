//
//  MoviesViewController.m
//  RottenFruit
//
//  Created by Brian Huang on 6/16/15.
//  Copyright (c) 2015 EC. All rights reserved.
//

#import "MoviesViewController.h"
#import "MovieCell.h"
#import "ViewController.h"
#import <UIImageView+AFNetworking.h>
#import <Reachability.h>

@interface MoviesViewController () <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *movies;
@property (strong, nonatomic) Reachability *reachability;
@property (strong, nonatomic) UIView *loadingView;
@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property (strong, nonatomic) UIView *refreshLoadingView;

@property (nonatomic) Reachability *hostReachability;
@property (nonatomic) Reachability *internetReachability;
@property (nonatomic) Reachability *wifiReachability;
@end

@implementation MoviesViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    
    self.internetReachability = [Reachability reachabilityForInternetConnection];
    [self.internetReachability startNotifier];
    [self updateInterfaceWithReachability:self.internetReachability];
    
    self.wifiReachability = [Reachability reachabilityForLocalWiFi];
    [self.wifiReachability startNotifier];
    [self updateInterfaceWithReachability:self.wifiReachability];
    
    [self showLoadingOverlay];
    [self setupRefreshControl];
    
    [self.tableView addSubview:self.refreshControl];
    [self loadData];
}

- (void) reachabilityChanged:(NSNotification *)note
{
    Reachability* curReach = [note object];
    NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
    [self updateInterfaceWithReachability:curReach];
}

- (void)updateInterfaceWithReachability:(Reachability *)reachability
{
    
    if (reachability == self.internetReachability)
    {
        [self configureTextField:reachability];
    }
    
    if (reachability == self.wifiReachability)
    {
        [self configureTextField:reachability];
    }
}

- (void)configureTextField:(Reachability *)reachability
{
    NetworkStatus netStatus = [reachability currentReachabilityStatus];
    
    switch (netStatus)
    {
            
        case NotReachable:        {
            [self generateErrorView];
            break;
        }
            
        case ReachableViaWWAN:        {
            [self removeErrorView];
            break;
        }
        case ReachableViaWiFi:        {
            [self removeErrorView];
            break;
        }
    }
}

-(void)generateErrorView{
    UIView *netWorkError = [[UIView alloc] initWithFrame:CGRectMake(0, 64, 320, 27)];
    netWorkError.tag = 123;
    [netWorkError setBackgroundColor:[UIColor lightGrayColor]];
    
    UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(107, 3, 107, 21)];
    messageLabel.text = @"Network Error";
    [netWorkError addSubview:messageLabel];
    
    
    [[UIApplication sharedApplication].keyWindow addSubview:netWorkError];
    
}

-(void)removeErrorView{
    UIView *netWorkError = (UIView *)[[UIApplication sharedApplication].keyWindow viewWithTag:123];
    //netWorkError.hidden = YES;
    [netWorkError removeFromSuperview];
}


- (void)setupRefreshControl
{
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.tableView addSubview:self.refreshControl];
    [self.refreshControl addTarget:self action:@selector(onRefresh:) forControlEvents:UIControlEventValueChanged];
}

- (void)onRefresh:(id)sender{
    NSLog(@"Refreshing");
    [self.refreshControl endRefreshing];
    [self loadData];
}

- (void)loadData {
    NSString *apiURLString = @"http://api.rottentomatoes.com/api/public/v1.0/lists/movies/box_office.json?apikey=dagqdghwaq3e3mxyrp7kmmj5&limit=20&country=us";
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:apiURLString]];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        self.movies = dict[@"movies"];
        [self.tableView reloadData];
        [self hideLoadingOverlay];
    }];
}

- (void)showLoadingOverlay {
    self.loadingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    [self.loadingView setTag:103];
    [self.loadingView setBackgroundColor:[UIColor blackColor]];
    [self.loadingView setAlpha:0.8];
    [self.view addSubview:self.loadingView];
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 32.0f, 32.0f)];
    [self.activityIndicator setCenter:self.loadingView.center];
    [self.activityIndicator setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhite];
    [self.loadingView addSubview:self.activityIndicator];
    [self.activityIndicator startAnimating];
    
    UILabel *msg = [[UILabel alloc] initWithFrame:CGRectMake(0, self.loadingView.frame.size.height/2 - 10, self.view.frame.size.width, 100)];
    msg.backgroundColor = [UIColor clearColor];
    msg.textAlignment = NSTextAlignmentCenter;
    msg.textColor = [UIColor whiteColor];
    msg.text = @"Loading ...";
    [self.loadingView addSubview:msg];
    
}

- (void)hideLoadingOverlay {
    self.loadingView.hidden = YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.movies.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MovieCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MyMovieCell" forIndexPath:indexPath];
    NSDictionary *movie = self.movies[indexPath.row];
    cell.titleLabel.text = movie[@"title"];
    cell.synopsisLabel.text = movie[@"synopsis"];
    NSString *posterURLString = [movie valueForKeyPath:@"posters.thumbnail"];
    [cell.posterView setImageWithURL:[NSURL URLWithString:posterURLString]];
    
    return cell;
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    MovieCell *cell = sender;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NSDictionary *movie = self.movies[indexPath.row];
    
    ViewController *destinationVC = segue.destinationViewController;
    destinationVC.movie = movie;
}


@end
