//
//  UserListingTableViewController.m
//  AudioVideoChat
//
//  Created by Ehsan Saddique on 14/01/2017.
//  Copyright © 2017 Ehsan Saddique. All rights reserved.
//

#import "UserListingTableViewController.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <Quickblox/Quickblox.h>
#import <QuickbloxWebRTC/QuickbloxWebRTC.h>
#import "DialViewController.h"
#import "QBCore.h"
#import "QBAVCallPermissions.h"

const NSString *applicationTag = @"LFDdating";
const NSUInteger kQBPageSize = 50;

@interface UserListingTableViewController () <DialViewControllerDelegate, QBCoreDelegate, QBRTCClientDelegate>

@property(nonatomic) NSMutableArray <QBUUser *> *dataSource;

@property (weak, nonatomic) QBRTCSession *session;

@property (weak, nonatomic) QBUUser *loggedInUser;

@end

@implementation UserListingTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    _dataSource = [NSMutableArray new];
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(onRfresh:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
    
    [Core addDelegate:self];
    [QBRTCClient.instance addDelegate:self];
    
    [self loginUser];
    
}

-(void)singupUser {
        QBUUser *user = [QBUUser user];
        user.password = @"ehsan";
        user.login = @"touheed";
    user.tags = @[applicationTag].mutableCopy;
    
        // Registration/sign up of User
        [QBRequest signUp:user successBlock:^(QBResponse* response, QBUUser* user) {
            // Sign up was successful
            NSLog(@"Successfull %@",user);
    
        } errorBlock:^(QBResponse *response) {
            // Handle error here
            NSLog(@"Failed %@",response);
    
        }];
}

-(void)loginUser {
    [QBRequest logInWithUserLogin:@"touheed" password:@"touheedgul"
                     successBlock:[self successBlock] errorBlock:[self errorBlock]];
}

-(void)onRfresh:(UIRefreshControl *) refreshControl {
    [self loadUsers];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _dataSource.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CellUser" forIndexPath:indexPath];
    
    QBUUser *user = [[QBUUser alloc] init];
    user = [_dataSource objectAtIndex:indexPath.row];
    cell.textLabel.text = user.login;
    
    return cell;
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    QBUUser *user = [[QBUUser alloc] init];
    user = [_dataSource objectAtIndex:indexPath.row];
    
    if (self.session) {
        return;
    }
    
    if ([self hasConnectivity]) {
        
        [QBAVCallPermissions checkPermissionsWithConferenceType:QBRTCConferenceTypeAudio completion:^(BOOL granted) {
            
            if (granted) {
                QBRTCSession *newSession = [[QBRTCClient instance] createNewSessionWithOpponents:@[[NSNumber numberWithUnsignedInteger:user.ID]]
                                                                              withConferenceType:QBRTCConferenceTypeAudio];
                self.session = newSession;
                [self.session startCall:nil];
                
                DialViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"DialViewController"];
                controller.user = user;
                controller.delegate = self;
                controller.session = self.session;
                controller.callType = CallTypeOutgoing;
                [self presentViewController:controller animated:YES completion:nil];
            }
        }];
    }
}

- (void (^)(QBResponse* response, QBUUser* user))successBlock
{
    return ^(QBResponse* response, QBUUser* user) {
        // Login succeeded
        NSLog(@"Successfull %@",user);
        
        self.title = [NSString stringWithFormat:@"LoggedIn : %@", user.login];
        self.loggedInUser = user;
        
        QBUUser *currentUser = [QBUUser user];
        currentUser.ID = 22765648;
        currentUser.password = @"ehsansaddique";
        
        // connect to Chat
        [[QBChat instance] connectWithUser:currentUser completion:^(NSError * _Nullable error) {
            
            NSLog(@"Eroor Is %@",error);
            
        }];
        
        
    };
}

- (QBRequestErrorBlock)errorBlock
{
    return ^(QBResponse *response) {
        // Handle error
        NSLog(@"Successfull %@",response);
    };
}

- (void)loadUsers {
    
    __block void(^t_request) (QBGeneralResponsePage *, NSMutableArray *);
    __weak __typeof(self)weakSelf = self;
    
    void(^request) (QBGeneralResponsePage *, NSMutableArray *) =
    ^(QBGeneralResponsePage *page, NSMutableArray *allUsers) {
        
        [QBRequest usersWithTags:@[applicationTag]
                            page:page
                    successBlock:^(QBResponse *response, QBGeneralResponsePage *page, NSArray<QBUUser *> *users)
         {
             page.currentPage++;
             [allUsers addObjectsFromArray:users];
             
             BOOL cancel;
             if (page.currentPage * page.perPage >= page.totalEntries) {
                 cancel = YES;
             }
             
             if (!cancel) {
                 t_request(page, allUsers);
                 
             }
             else {
                 
                 [weakSelf.refreshControl endRefreshing];
                 [weakSelf.dataSource removeAllObjects];
                 weakSelf.dataSource = allUsers;
                 
                 QBUUser *toRemove = [[QBUUser alloc] init];
                 for (QBUUser *mUser in weakSelf.dataSource) {
                     if (mUser.ID == weakSelf.loggedInUser.ID) {
                         toRemove = mUser;
                     }
                 }
                 [weakSelf.dataSource removeObject:toRemove];
                 
                 [weakSelf.tableView reloadData];
                 t_request = nil;
             }
             
         } errorBlock:^(QBResponse *response) {
             
             [weakSelf.refreshControl endRefreshing];
             t_request = nil;
         }];
    } ;
    
    t_request = [request copy];
    
    QBGeneralResponsePage *responsePage =
    [QBGeneralResponsePage responsePageWithCurrentPage:1 perPage:kQBPageSize];
    NSMutableArray *allUsers = [NSMutableArray array];
    
    request(responsePage, allUsers);
}

#pragma mark - Utility

- (BOOL)hasConnectivity {
    
    BOOL hasConnectivity = Core.networkStatus != QBNetworkStatusNotReachable;
    
    if (!hasConnectivity) {
        [self showAlertViewWithMessage:NSLocalizedString(@"Please check your Internet connection", nil)];
    }
    
    return hasConnectivity;
}

- (void)showAlertViewWithMessage:(NSString *)message {
    
    UIAlertController *alertController =
    [UIAlertController alertControllerWithTitle:nil
                                        message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Ok", nil)
                                                        style:UIAlertActionStyleDefault
                                                      handler:nil]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - QBWebRTCChatDelegate

-(void)didReceiveNewSession:(QBRTCSession *)session userInfo:(NSDictionary<NSString *,NSString *> *)userInfo {
    if (self.session ) {
        
        [session rejectCall:@{@"reject" : @"busy"}];
        return;
    }
    
    self.session = session;
    
    [[QBRTCAudioSession instance] initializeWithConfigurationBlock:^(QBRTCAudioSessionConfiguration *configuration) {
        
        // adding bluetooth and airplay support
        configuration.categoryOptions |= AVAudioSessionCategoryOptionAllowBluetooth;
        configuration.categoryOptions |= AVAudioSessionCategoryOptionAllowBluetoothA2DP;
        configuration.categoryOptions |= AVAudioSessionCategoryOptionAllowAirPlay;
        
        if (session.conferenceType == QBRTCConferenceTypeVideo) {
            // setting mode to video chat to enable airplay audio and speaker only
            configuration.mode = AVAudioSessionModeVideoChat;
        }
    }];
    
    [QBRequest userWithID:self.session.initiatorID.integerValue successBlock:^(QBResponse * _Nonnull response, QBUUser * _Nullable user) {
        
        DialViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"DialViewController"];
        controller.user = user;
        controller.delegate = self;
        controller.callType = CallTypeIncoming;
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self];
        [navController presentViewController:controller animated:YES completion:nil];
        
    } errorBlock:^(QBResponse * _Nonnull response) {
        
    }];
}

- (void)sessionDidClose:(QBRTCSession *)session {
    
    if (session == self.session ) {
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            [self.navigationController dismissViewControllerAnimated:NO completion:nil];
            self.session = nil;
        });
    }
}

#pragma mark - DialViewControllerDelegate

-(void)dialViewController:(DialViewController *)vc didAcceptSession:(QBRTCSession *)session {
    [session acceptCall:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)dialViewController:(DialViewController *)vc didRejectSession:(QBRTCSession *)session {
    [session rejectCall:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
