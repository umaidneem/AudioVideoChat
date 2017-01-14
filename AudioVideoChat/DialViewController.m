//
//  DialViewController.m
//  AudioVideoChat
//
//  Created by Ehsan Saddique on 14/01/2017.
//  Copyright © 2017 Ehsan Saddique. All rights reserved.
//

#import "DialViewController.h"
#import "QMSoundManager.h"

@interface DialViewController () <QBRTCClientDelegate>

@property (weak, nonatomic) NSTimer *dialingTimer;

@end

@implementation DialViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[QBRTCClient instance] addDelegate:self];
    
    if (_callType == CallTypeOutgoing) {
        [self startOutgoingCall];
    }
    
    self.dialingTimer = [NSTimer scheduledTimerWithTimeInterval:[QBRTCConfig dialingTimeInterval]
                                                         target:self
                                                       selector:@selector(dialing:)
                                                       userInfo:nil
                                                        repeats:YES];
    
}

- (void)startOutgoingCall {
    
    self.title = @"Connecting..";
    
    
}

- (void)dialing:(NSTimer *)timer {
    
    if (_callType == CallTypeIncoming) {
        [QMSoundManager playRingtoneSound];
    }
    else {
        [QMSoundManager playCallingSound];
    }
}

#pragma mark - Actions

- (void)cleanUp {
    
    [self.dialingTimer invalidate];
    self.dialingTimer = nil;
    
    [QBRTCClient.instance removeDelegate:self];
    [[QMSoundManager instance] stopAllSounds];
}

- (void)sessionDidClose:(QBRTCSession *)session {
    
    if (self.session == session) {
        [self cleanUp];
        [[QBRTCAudioSession instance] deinitialize];
    }
}

#pragma mark - IBActions
- (IBAction)btnAcceptTapped:(id)sender {
    [self cleanUp];
    [_delegate dialViewController:self didAcceptSession:self.session];
}

- (IBAction)btnRejectTapped:(id)sender {
    [self cleanUp];
    [_delegate dialViewController:self didRejectSession:self.session];
}

#pragma mark - QBWebRTCChatDelegate

- (void)didReceiveNewSession:(QBRTCSession *)session userInfo:(NSDictionary *)userInfo {
    
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
//        controller.delegate = self;
//        controller.callType = CallTypeIncoming;
//        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self];
//        [navController presentViewController:controller animated:YES completion:nil];
        
    } errorBlock:^(QBResponse * _Nonnull response) {
        
    }];
}


@end
