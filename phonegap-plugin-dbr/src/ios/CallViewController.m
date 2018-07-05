//
//  CallViewController.m
//  QBRTCChatSemple
//
//  Created by Andrey Ivanov on 11.12.14.
//  Copyright (c) 2014 QuickBlox Team. All rights reserved.
//

#import "CallViewController.h"
#import "LocalVideoView.h"
#import "QBCore.h"

@interface CallViewController ()

<UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, QBRTCClientDelegate, QBRTCAudioSessionDelegate, LocalVideoViewDelegate>
@property (strong, nonatomic) QBRTCCameraCapture *cameraCapture;
@property (strong, nonatomic) NSMutableDictionary *videoViews;
@property (weak, nonatomic) LocalVideoView *localVideoView;

@end

@implementation CallViewController

// MARK: - Life cycle

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSLog(@"%@ - %@",  NSStringFromSelector(_cmd), self);
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [[QBRTCClient instance] addDelegate:self];
    [[QBRTCAudioSession instance] addDelegate:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    QBRTCAudioSession *audioSession = [QBRTCAudioSession instance];
    if (!audioSession.isInitialized) {
        [audioSession initializeWithConfigurationBlock:^(QBRTCAudioSessionConfiguration *configuration) {
            // adding blutetooth support
            configuration.categoryOptions |= AVAudioSessionCategoryOptionAllowBluetooth;
            configuration.categoryOptions |= AVAudioSessionCategoryOptionAllowBluetoothA2DP;
            
            // adding airplay support
            configuration.categoryOptions |= AVAudioSessionCategoryOptionAllowAirPlay;
            
            if (_session.conferenceType == QBRTCConferenceTypeVideo) {
                // setting mode to video chat to enable airplay audio and speaker only
                configuration.mode = AVAudioSessionModeVideoChat;
            }
        }];
    }
    
//    [self configureGUI];
    
    if (self.session.conferenceType == QBRTCConferenceTypeVideo) {
        
#if !(TARGET_IPHONE_SIMULATOR)
        self.cameraCapture = [[QBRTCCameraCapture alloc] initWithVideoFormat:settings.videoFormat
                                                                    position:settings.preferredCameraPostion];
        [self.cameraCapture startSession:nil];
        self.session.localMediaStream.videoTrack.videoCapture = self.cameraCapture;
#endif
    }
    
//    self.view.backgroundColor = self.opponentsCollectionView.backgroundColor =
//    [UIColor colorWithRed:0.1465 green:0.1465 blue:0.1465 alpha:1.0];
    
    NSMutableArray *users = [NSMutableArray arrayWithCapacity:self.session.opponentsIDs.count + 1];
    [users insertObject:Core.currentUser atIndex:0];
//
//    for (NSNumber *uID in self.session.opponentsIDs) {
//
//        if (Core.currentUser.ID == uID.integerValue) {
//
//            QBUUser *initiator = [self.usersDatasource userWithID:self.session.initiatorID.unsignedIntegerValue];
//
//            if (!initiator) {
//
//                initiator = [QBUUser user];
//                initiator.ID = self.session.initiatorID.integerValue;
//            }
//
//            [users insertObject:initiator atIndex:0];
//
//            continue;
//        }
//
//        QBUUser *user = [self.usersDatasource userWithID:uID.integerValue];
//        if (!user) {
//            user = [QBUUser user];
//            user.ID = uID.integerValue;
//        }
//        [users insertObject:user atIndex:0];
//    }
//
//    self.users = users;
//
//    BOOL isInitiator = (Core.currentUser.ID == self.session.initiatorID.unsignedIntegerValue);
//    isInitiator ? [self startCall] : [self acceptCall];
//
    self.title = @"Connecting...";
    
//    if (CallKitManager.isCallKitAvailable
//        && [self.session.initiatorID integerValue] == Core.currentUser.ID) {
//        [CallKitManager.instance updateCallWithUUID:_callUUID connectingAtDate:[NSDate date]];
//    }
}
//
//- (void)configureGUI {
//
//    __weak __typeof(self)weakSelf = self;
//
//    if (self.session.conferenceType == QBRTCConferenceTypeVideo) {
//
//        self.videoEnabled = [QBButtonsFactory videoEnable];
//        [self.toolbar addButton:self.videoEnabled action: ^(UIButton *sender) {
//
//            weakSelf.session.localMediaStream.videoTrack.enabled ^=1;
//            weakSelf.localVideoView.hidden = !weakSelf.session.localMediaStream.videoTrack.enabled;
//        }];
//    }
//
//    self.audioEnabled = [QBButtonsFactory auidoEnable];
//    [self.toolbar addButton:self.audioEnabled action: ^(UIButton *sender) {
//
//        weakSelf.session.localMediaStream.audioTrack.enabled ^=1;
//        weakSelf.session.recorder.microphoneMuted = !weakSelf.session.localMediaStream.audioTrack.enabled;
//    }];
//
//    [CallKitManager.instance setOnMicrophoneMuteAction:^{
//        weakSelf.audioEnabled.pressed ^= 1;
//        weakSelf.session.recorder.microphoneMuted = weakSelf.audioEnabled.pressed;
//    }];
//
//    if (self.session.conferenceType == QBRTCConferenceTypeAudio) {
//
//        self.dynamicEnable = [QBButtonsFactory dynamicEnable];
//        [self.toolbar addButton:self.dynamicEnable action:^(UIButton *sender) {
//
//            QBRTCAudioDevice device = [QBRTCAudioSession instance].currentAudioDevice;
//
//            [QBRTCAudioSession instance].currentAudioDevice =
//            device == QBRTCAudioDeviceSpeaker ? QBRTCAudioDeviceReceiver : QBRTCAudioDeviceSpeaker;
//        }];
//    }
//
//    if (self.session.conferenceType == QBRTCConferenceTypeVideo) {
//
//        [self.toolbar addButton:[QBButtonsFactory screenShare] action: ^(UIButton *sender) {
//
//            SharingViewController *sharingVC =
//            [weakSelf.storyboard instantiateViewControllerWithIdentifier:kSharingViewControllerIdentifier];
//            sharingVC.session = weakSelf.session;
//
//            // put camera capture on pause
//            [weakSelf.cameraCapture stopSession:nil];
//
//            [weakSelf.navigationController pushViewController:sharingVC animated:YES];
//        }];
//    }
//
//    [self.toolbar addButton:[QBButtonsFactory decline] action: ^(UIButton *sender) {
//
//        [weakSelf.callTimer invalidate];
//        weakSelf.callTimer = nil;
//
//        if (weakSelf.session.recorder.state == QBRTCRecorderStateActive) {
//            [SVProgressHUD showWithStatus:NSLocalizedString(@"Saving record", nil)];
//            [weakSelf.session.recorder stopRecord:^(NSURL *file) {
//                [SVProgressHUD dismiss];
//            }];
//        }
//        [weakSelf.session hangUp:@{@"hangup" : @"hang up"}];
//    }];
//
//    [self.toolbar updateItems];
//
//    // zoomed view
//    _zoomedView = prepareSubview(self.view, [ZoomedView class]);
//    [_zoomedView setDidTapView:^(ZoomedView *zoomedView) {
//        [weakSelf unzoomVideoView];
//    }];
//    // stats view
//    _statsView = prepareSubview(self.view, [StatsView class]);
//    [_statsView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(updateStatsState)]];
//
//    // add button to enable stats view
//    self.statsItem = [[UIBarButtonItem alloc] initWithTitle:@"Stats"
//                                                      style:UIBarButtonItemStylePlain
//                                                     target:self
//                                                     action:@selector(updateStatsView)];
//}
//
//- (void)viewDidAppear:(BOOL)animated {
//    [super viewDidAppear:animated];
//
//    [self refreshVideoViews];
//
//    if (self.cameraCapture != nil
//        && !self.cameraCapture.hasStarted) {
//        // ideally you should always stop capture session
//        // when you are leaving controller in any way
//        // here we should get its running state back
//        [self.cameraCapture startSession:nil];
//    }
//}
//
//// MARK: - UICollectionViewDataSource
//
//- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
//
//    return self.users.count;
//}
//
//- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
//
//    OpponentCollectionViewCell *reusableCell = [collectionView
//                                                dequeueReusableCellWithReuseIdentifier:kOpponentCollectionViewCellIdentifier
//                                                forIndexPath:indexPath];
//    QBUUser *user = self.users[indexPath.row];
//    NSNumber *userID = @(user.ID);
//
//    __weak __typeof(self)weakSelf = self;
//    [reusableCell setDidPressMuteButton:^(BOOL isMuted) {
//
//        QBRTCAudioTrack *audioTrack = [weakSelf.session remoteAudioTrackWithUserID:userID];
//        audioTrack.enabled = !isMuted;
//    }];
//
//    [reusableCell setVideoView:[self videoViewWithOpponentID:userID]];
//    reusableCell.connectionState = [self.session connectionStateForUser:userID];
//
//    if (user.ID != [QBSession currentSession].currentUser.ID) {
//
//        NSString *title = user.fullName ?: kUnknownUserLabel;
//        reusableCell.name = title;
//        reusableCell.nameColor = [PlaceholderGenerator colorForString:title];
//    }
//
//    return reusableCell;
//}
//
//- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
//
//    QBUUser *user = self.users[indexPath.item];
//    if (user.ID == self.session.currentUserID.unsignedIntegerValue) {
//        // do not zoom local video view
//        return;
//    }
//
//    OpponentCollectionViewCell *videoCell = (OpponentCollectionViewCell *)[self.opponentsCollectionView cellForItemAtIndexPath:indexPath];
//    UIView *videoView = videoCell.videoView;
//
//    if (videoView != nil) {
//        videoCell.videoView = nil;
//        self.originCell = videoCell;
//        _statsUserID = @(user.ID);
//        [self zoomVideoView:videoView];
//    }
//    else if (_session.conferenceType == QBRTCConferenceTypeAudio) {
//        // just show stats on click if in audio call
//        _statsUserID = @(user.ID);
//        [self updateStatsView];
//    }
//}
//
//// MARK: - Transition to size
//
//- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
//    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
//
//    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
//
//        [self refreshVideoViews];
//
//    } completion:nil];
//}
//
//// MARK: - QBRTCClientDelegate
//
//- (void)session:(QBRTCSession *)session updatedStatsReport:(QBRTCStatsReport *)report forUserID:(NSNumber *)userID {
//
//    if (session == self.session) {
//
//        [self performUpdateUserID:userID block:^(OpponentCollectionViewCell *cell) {
//            if (cell.connectionState == QBRTCConnectionStateConnected
//                && report.videoReceivedBitrateTracker.bitrate > 0) {
//                [cell setBitrateString:report.videoReceivedBitrateTracker.bitrateString];
//            }
//        }];
//
//        if ([_statsUserID isEqualToNumber:userID]) {
//
//            QBUUser *user = [self.usersDatasource userWithID:userID.integerValue];
//            NSString *result = [NSString stringWithFormat:@"User: %@\n%@", user.fullName ?: userID,[report statsString]];
//            NSLog(@"%@", result);
//
//            // send stats to stats view if needed
//            if (_shouldGetStats) {
//                [_statsView setStats:result];
//                [self.view setNeedsLayout];
//            }
//        }
//    }
//}
//
//- (void)session:(QBRTCSession *)session didChangeConnectionState:(QBRTCConnectionState)state forUser:(NSNumber *)userID {
//
//    if (session == self.session) {
//
//        [self performUpdateUserID:userID block:^(OpponentCollectionViewCell *cell) {
//            cell.connectionState = state;
//        }];
//    }
//}
//
///**
// *  Called in case when receive remote video track from opponent
// */
//- (void)session:(QBRTCSession *)session receivedRemoteVideoTrack:(QBRTCVideoTrack *)videoTrack fromUser:(NSNumber *)userID {
//
//    if (session == self.session) {
//
//        [self performUpdateUserID:userID block:^(OpponentCollectionViewCell *cell) {
//
//            QBRTCRemoteVideoView *opponentVideoView = (id)[self videoViewWithOpponentID:userID];
//            [cell setVideoView:opponentVideoView];
//        }];
//    }
//}
//
///**
// *  Called in case when connection is established with opponent
// */
//- (void)session:(QBRTCSession *)session connectedToUser:(NSNumber *)userID {
//
//    if (session == self.session) {
//
//        if (self.beepTimer) {
//
//            [self.beepTimer invalidate];
//            self.beepTimer = nil;
//            [[QMSoundManager instance] stopAllSounds];
//        }
//
//        if (!self.callTimer) {
//
//            if (CallKitManager.isCallKitAvailable
//                && [self.session.initiatorID integerValue] == Core.currentUser.ID) {
//                [CallKitManager.instance updateCallWithUUID:_callUUID connectedAtDate:[NSDate date]];
//            }
//
//            self.callTimer = [NSTimer scheduledTimerWithTimeInterval:kRefreshTimeInterval
//                                                              target:self
//                                                            selector:@selector(refreshCallTime:)
//                                                            userInfo:nil
//                                                             repeats:YES];
//        }
//    }
//}
//
///**
// *  Called in case when connection state changed
// */
//- (void)session:(QBRTCSession *)session connectionClosedForUser:(NSNumber *)userID {
//
//    if (session == self.session) {
//
//        [self performUpdateUserID:userID block:^(OpponentCollectionViewCell *cell) {            [self.videoViews removeObjectForKey:userID];
//            [cell setVideoView:nil];
//        }];
//    }
//}
//
///**
// *  Called in case when session will close
// */
//- (void)sessionDidClose:(QBRTCSession *)session {
//
//    if (session == self.session) {
//
//        if (CallKitManager.isCallKitAvailable) {
//            [CallKitManager.instance endCallWithUUID:_callUUID completion:nil];
//        }
//
//        if (self.session.recorder.state == QBRTCRecorderStateActive) {
//            [SVProgressHUD showWithStatus:NSLocalizedString(@"Saving record", nil)];
//            [self.session.recorder stopRecord:^(NSURL *file) {
//                [SVProgressHUD dismiss];
//            }];
//        }
//
//        [self.cameraCapture stopSession:nil];
//
//        QBRTCAudioSession *audioSession = [QBRTCAudioSession instance];
//        if (audioSession.isInitialized
//            && ![audioSession audioSessionIsActivatedOutside:[AVAudioSession sharedInstance]]) {
//            NSLog(@"Deinitializing QBRTCAudioSession in CallViewController.");
//            [audioSession deinitialize];
//        }
//
//        if (self.beepTimer) {
//
//            [self.beepTimer invalidate];
//            self.beepTimer = nil;
//            [[QMSoundManager instance] stopAllSounds];
//        }
//
//        [self.callTimer invalidate];
//        self.callTimer = nil;
//
//        self.toolbar.userInteractionEnabled = NO;
//        [UIView animateWithDuration:0.5 animations:^{
//
//            self.toolbar.alpha = 0.4;
//        }];
//
//        self.title = [NSString stringWithFormat:@"End - %@", [self stringWithTimeDuration:self.timeDuration]];
//    }
//}
//
//// MARK: - QBRTCAudioSessionDelegate
//
//- (void)audioSession:(QBRTCAudioSession *)audioSession didChangeCurrentAudioDevice:(QBRTCAudioDevice)updatedAudioDevice {
//
//    BOOL isSpeaker = updatedAudioDevice == QBRTCAudioDeviceSpeaker;
//    if (self.dynamicEnable.pressed != isSpeaker) {
//
//        self.dynamicEnable.pressed = isSpeaker;
//    }
//}
//
//// MARK: - Timers actions
//
//- (void)playCallingSound:(id)sender {
//
//    [QMSoundManager playCallingSound];
//}
//
//- (void)refreshCallTime:(NSTimer *)sender {
//
//    self.timeDuration += kRefreshTimeInterval;
//    NSString *extraTitle = @"";
//    if (self.session.recorder.state == QBRTCRecorderStateActive) {
//        extraTitle = kQBRTCRecordingTitle;
//    }
//    self.title = [NSString stringWithFormat:@"%@Call time - %@", extraTitle, [self stringWithTimeDuration:self.timeDuration]];
//}
//
//- (NSString *)stringWithTimeDuration:(NSTimeInterval )timeDuration {
//
//    NSInteger minutes = timeDuration / 60;
//    NSInteger seconds = (NSInteger)timeDuration % 60;
//
//    NSString *timeStr = [NSString stringWithFormat:@"%ld:%02ld", (long)minutes, (long)seconds];
//
//    return timeStr;
//}

- (void)localVideoView:(LocalVideoView *)localVideoView pressedSwitchButton:(UIButton *)sender {

    AVCaptureDevicePosition position = self.cameraCapture.position;
    AVCaptureDevicePosition newPosition = position == AVCaptureDevicePositionBack ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;

    if ([self.cameraCapture hasCameraForPosition:newPosition]) {

        CATransition *animation = [CATransition animation];
        animation.duration = .75f;
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        animation.type = @"oglFlip";

        if (position == AVCaptureDevicePositionFront) {

            animation.subtype = kCATransitionFromRight;
        }
        else if(position == AVCaptureDevicePositionBack) {

            animation.subtype = kCATransitionFromLeft;
        }

        [localVideoView.superview.layer addAnimation:animation forKey:nil];
        self.cameraCapture.position = newPosition;
    }
}
//
//// MARK: - Actions
//
//- (void)refreshVideoViews {
//
//    // resetting zoomed view
//    UIView *zoomedVideoView = self.zoomedView.videoView;
//    for (OpponentCollectionViewCell *viewToRefresh  in self.opponentsCollectionView.visibleCells) {
//        UIView *view = viewToRefresh.videoView;
//        if (view == zoomedVideoView) {
//            continue;
//        }
//
//        [viewToRefresh setVideoView:nil];
//        [viewToRefresh setVideoView:view];
//    }
//}
//
//- (void)startCall {
//    //Begin play calling sound
//    self.beepTimer = [NSTimer scheduledTimerWithTimeInterval:[QBRTCConfig dialingTimeInterval]
//                                                      target:self
//                                                    selector:@selector(playCallingSound:)
//                                                    userInfo:nil
//                                                     repeats:YES];
//    [self playCallingSound:nil];
//    //Start call
//    NSDictionary *userInfo = @{@"name" : @"Test",
//                               @"url" : @"http.quickblox.com",
//                               @"param" : @"\"1,2,3,4\""};
//
//    [self.session startCall:userInfo];
//}
//
//- (void)acceptCall {
//
//    [[QMSoundManager instance] stopAllSounds];
//    //Accept call
//    NSDictionary *userInfo = @{@"acceptCall" : @"userInfo"};
//    [self.session acceptCall:userInfo];
//}
//
//- (void)performUpdateUserID:(NSNumber *)userID block:(void(^)(OpponentCollectionViewCell *cell))block {
//
//    NSIndexPath *indexPath = [self indexPathAtUserID:userID];
//    OpponentCollectionViewCell *cell = (id)[self.opponentsCollectionView cellForItemAtIndexPath:indexPath];
//    block(cell);
//}
//
//- (void)updateStatsView {
//    self.shouldGetStats ^= 1;
//    self.statsView.hidden ^= 1;
//}
//
//- (void)updateStatsState {
//    [self updateStatsView];
//    if (!_shouldGetStats) {
//        _statsUserID = nil;
//    }
//}
//
//- (void)zoomVideoView:(UIView *)videoView {
//    [_zoomedView setVideoView:videoView];
//    _zoomedView.hidden = NO;
//    self.navigationItem.rightBarButtonItem = self.statsItem;
//}
//
//- (void)unzoomVideoView {
//    if (self.originCell != nil) {
//        self.originCell.videoView = _zoomedView.videoView;
//        _zoomedView.videoView = nil;
//        self.originCell = nil;
//        _zoomedView.hidden = YES;
//        _statsUserID = nil;
//        self.navigationItem.rightBarButtonItem = nil;
//    }
//}
//
//// MARK: - Helpers
//
//static inline __kindof UIView *prepareSubview(UIView *view, Class subviewClass) {
//
//    UIView *subview = [[subviewClass alloc] initWithFrame:view.bounds];
//    subview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
//    subview.hidden = YES;
//    [view addSubview:subview];
//    return subview;
//}

- (UIView *)videoViewWithOpponentID:(NSNumber *)opponentID {

    if (self.session.conferenceType == QBRTCConferenceTypeAudio) {
        return nil;
    }

    if (!self.videoViews) {
        self.videoViews = [NSMutableDictionary dictionary];
    }

    id result = self.videoViews[opponentID];

    if (Core.currentUser.ID == opponentID.integerValue) {//Local preview

        if (!result) {

            LocalVideoView *localVideoView = [[LocalVideoView alloc] initWithPreviewlayer:self.cameraCapture.previewLayer];
            self.videoViews[opponentID] = localVideoView;
            localVideoView.delegate = self;
            self.localVideoView = localVideoView;

            return localVideoView;
        }
    }
    else {//Opponents

        QBRTCRemoteVideoView *remoteVideoView = nil;

        QBRTCVideoTrack *remoteVideoTraсk = [self.session remoteVideoTrackWithUserID:opponentID];

        if (!result && remoteVideoTraсk) {

            remoteVideoView = [[QBRTCRemoteVideoView alloc] initWithFrame:CGRectMake(2, 2, 2, 2)];
            remoteVideoView.videoGravity = AVLayerVideoGravityResizeAspectFill;
            self.videoViews[opponentID] = remoteVideoView;
            result = remoteVideoView;
        }

        [remoteVideoView setVideoTrack:remoteVideoTraсk];

        return result;
    }

    return result;
}
//
//- (NSIndexPath *)indexPathAtUserID:(NSNumber *)userID {
//
//    QBUUser *user = [self.usersDatasource userWithID:userID.unsignedIntegerValue];
//
//    if (!user) {
//        user = [QBUUser user];
//        user.ID = userID.unsignedIntegerValue;
//    }
//    NSUInteger idx = [self.users indexOfObject:user];
//    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idx inSection:0];
//
//    return indexPath;
//}

@end
