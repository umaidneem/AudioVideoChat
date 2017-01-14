//
//  DialViewController.h
//  AudioVideoChat
//
//  Created by Ehsan Saddique on 14/01/2017.
//  Copyright © 2017 Ehsan Saddique. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <Quickblox/Quickblox.h>
#import <QuickbloxWebRTC/QuickbloxWebRTC.h>
@class DialViewController;

@protocol DialViewControllerDelegate

- (void)dialViewController:(DialViewController *)vc didAcceptSession:(QBRTCSession *)session;
- (void)dialViewController:(DialViewController *)vc didRejectSession:(QBRTCSession *)session;

@end

@interface DialViewController : UIViewController

typedef NS_ENUM(NSInteger, CallType) {
    CallTypeIncoming,
    CallTypeOutgoing
};

@property (weak, nonatomic) id <DialViewControllerDelegate> delegate;

@property (weak, nonatomic) IBOutlet UIButton *btnReject;

@property (weak, nonatomic) IBOutlet UIButton *btnAccept;
@property (weak, nonatomic) IBOutlet UILabel *lblCaller;

@property (weak, nonatomic) QBRTCSession *session;


@property (nonatomic) CallType callType;
@property (strong, nonatomic) QBUUser *user;

@end
