//
//  QBViewController.m
//  MPC
//
//  Created by Software Engineer on 4/18/18.
//

#import "QBViewController.h"

#import <Quickblox/Quickblox.h>
#import <QuickbloxWebRTC/QuickbloxWebRTC.h>
#import "CDVBarcodeScanner.h"

@interface QBViewController()
<QBRTCClientDelegate, QBRTCAudioSessionDelegate>

@property (strong, nonatomic) QBRTCCameraCapture *videoCapture;

@property (nonatomic) IBOutlet QBRTCRemoteVideoView *remoteVideoView;
@property (nonatomic) IBOutlet UIView *localVideoView;
@property (nonatomic) IBOutlet UILabel *userName;
@property (nonatomic) IBOutlet UILabel *timer;
@property (nonatomic) IBOutlet UILabel *userName1;
@property (nonatomic) IBOutlet UILabel *timer1;
@property (nonatomic) IBOutlet UIButton *btAudio;
@property (nonatomic) IBOutlet UIButton *btSpeaker;
@property (nonatomic) IBOutlet UIButton *btVideoAudio;
@property (nonatomic) IBOutlet UIButton *btVideo;

@property (nonatomic) IBOutlet UIView *videoView;
@property (nonatomic) IBOutlet UIView *audioView;

@property (strong, nonatomic) QBRTCVideoFormat *videoFormat;

@property (weak, nonatomic) UIView *vv;

- (IBAction)cancel;
- (IBAction)flip;
- (IBAction)muteAudio;
- (IBAction)muteVideoAudio;
- (IBAction)muteVideo;
- (IBAction)actSpeaker;
- (IBAction)goVideo;
- (IBAction)goAudio;
- (void)endCall;

@end

@implementation QBViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [[QBRTCClient instance] addDelegate:self];
    [[QBRTCAudioSession instance] addDelegate:self];
    
    [self.userName setText:self.name];
    [self.timer setText:@"Calling..."];
    [self.userName1 setText:self.name];
    [self.timer1 setText:@"Calling..."];
    
    self.TimeOfActiveUser = nil;
    self.tt = 0;
    self.isMuteAudio = false;
    
    [self initVideo];
    
    // start call
    
//    [[QBRTCAudioSession instance] initialize];
    [[QBRTCAudioSession instance] initializeWithConfigurationBlock:^(QBRTCAudioSessionConfiguration *configuration) {
        // adding blutetooth support
        configuration.categoryOptions |= AVAudioSessionCategoryOptionAllowBluetooth;
        configuration.categoryOptions |= AVAudioSessionCategoryOptionAllowBluetoothA2DP;
        
        // adding airplay support
        configuration.categoryOptions |= AVAudioSessionCategoryOptionAllowAirPlay;
        
        if (_session.conferenceType == QBRTCConferenceTypeVideo) {
            // setting mode to video chat to enable airplay audio and speaker only
//            configuration.mode = AVAudioSessionModeVideoChat;
        }
    }];
//    [QBRTCAudioSession instance].currentAudioDevice = QBRTCAudioDeviceReceiver;
    
    [self initView];
    
}

- (void) initVideo {
#if !(TARGET_IPHONE_SIMULATOR)
    self.videoFormat = [[QBRTCVideoFormat alloc] init];
    self.videoFormat.frameRate = 30;
    self.videoFormat.pixelFormat = QBRTCPixelFormat420f;
    self.videoFormat.width = 640;
    self.videoFormat.height = 480;
    
    // QBRTCCameraCapture class used to capture frames using AVFoundation APIs
    self.videoCapture = [[QBRTCCameraCapture alloc] initWithVideoFormat:self.videoFormat position:AVCaptureDevicePositionFront]; // or AVCaptureDevicePositionBack
    
    // add video capture to session's local media stream
    // from version 2.3 you no longer need to wait for 'initializedLocalMediaStream:' delegate to do it
    self.session.localMediaStream.videoTrack.videoCapture = self.videoCapture;
    
    self.videoCapture.previewLayer.frame = CGRectMake(0, 0, self.localVideoView.bounds.size.width, self.localVideoView.bounds.size.height);
    [self.videoCapture startSession:nil];
    
    [self.localVideoView.layer insertSublayer:self.videoCapture.previewLayer atIndex:0];
    self.localVideoView.layer.borderColor = [UIColor colorWithWhite:1.0f alpha:1.0f].CGColor;
    self.localVideoView.layer.borderWidth = 1.0f;
#endif
}

- (void)updateVideo {
    [self.videoCapture stopSession:nil];
#if !(TARGET_IPHONE_SIMULATOR)
    self.videoFormat = [[QBRTCVideoFormat alloc] init];
    self.videoFormat.frameRate = 30;
    self.videoFormat.pixelFormat = QBRTCPixelFormat420f;
    self.videoFormat.width = 640;
    self.videoFormat.height = 480;
    
    // QBRTCCameraCapture class used to capture frames using AVFoundation APIs
    self.videoCapture = [[QBRTCCameraCapture alloc] initWithVideoFormat:self.videoFormat position:AVCaptureDevicePositionFront]; // or AVCaptureDevicePositionBack
    
    // add video capture to session's local media stream
    // from version 2.3 you no longer need to wait for 'initializedLocalMediaStream:' delegate to do it
    self.session.localMediaStream.videoTrack.videoCapture = self.videoCapture;
    
    self.videoCapture.previewLayer.frame = CGRectMake(0, 0, self.localVideoView.bounds.size.width, self.localVideoView.bounds.size.height);
    [self.videoCapture startSession:nil];
    
    for (CALayer *layer in self.localVideoView.layer.sublayers) {
        [layer removeFromSuperlayer];
    }
    [self.localVideoView.layer insertSublayer:self.videoCapture.previewLayer atIndex:0];
    self.localVideoView.layer.borderColor = [UIColor colorWithWhite:1.0f alpha:1.0f].CGColor;
    self.localVideoView.layer.borderWidth = 1.0f;
#endif
    
    NSTimer *tTimer = [NSTimer scheduledTimerWithTimeInterval:3  target:self selector:@selector(initView) userInfo:nil repeats:NO];
    [tTimer fire];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.remoteVideoView.videoGravity = AVLayerVideoGravityResizeAspectFill;
}

// IBAction
- (IBAction)flip {
    AVCaptureDevicePosition position = self.videoCapture.position;
    AVCaptureDevicePosition newPosition = position == AVCaptureDevicePositionBack ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
    
    if ([self.videoCapture hasCameraForPosition:newPosition]) {
        self.videoCapture.position = newPosition;
    }
}
- (IBAction)muteAudio {
    self.session.localMediaStream.audioTrack.enabled = !self.session.localMediaStream.audioTrack.isEnabled;
    if (self.session.localMediaStream.audioTrack.isEnabled) {
        self.isMuteAudio = false;
        [self.btAudio setBackgroundImage:[UIImage imageNamed:@"mic.png"] forState:UIControlStateNormal];
        [self.btVideoAudio setBackgroundImage:[UIImage imageNamed:@"mic.png"] forState:UIControlStateNormal];
    } else {
        self.isMuteAudio = true;
        [self.btAudio setBackgroundImage:[UIImage imageNamed:@"mic_mute.png"] forState:UIControlStateNormal];
        [self.btVideoAudio setBackgroundImage:[UIImage imageNamed:@"mic_mute.png"] forState:UIControlStateNormal];
    }
}
- (IBAction)muteVideoAudio {
    [self muteAudio];
}
- (IBAction)muteVideo {
    self.session.localMediaStream.videoTrack.enabled = !self.session.localMediaStream.videoTrack.isEnabled;
    if (self.session.localMediaStream.videoTrack.isEnabled) {
        [self.btVideo setBackgroundImage:[UIImage imageNamed:@"video.png"] forState:UIControlStateNormal];
    } else {
        [self.btVideo setBackgroundImage:[UIImage imageNamed:@"video_mute.png"] forState:UIControlStateNormal];
    }
}
- (void)endCall {
    [self.videoCapture stopSession:nil];
    [self.session hangUp:nil];
    
    if (![self.reCall isEqualToString:@"1"]) {
        [[QBRTCClient instance] removeDelegate:self];
        [[QBRTCAudioSession instance] removeDelegate:self];
        [self.TimeOfActiveUser invalidate];
        self.TimeOfActiveUser = nil;
        
        self.reCall = @"0";
        self.parent.reCall = @"0";
        
        [self dismissViewControllerAnimated:NO completion:nil];
    }
}
- (IBAction)cancel {
    [self.videoCapture stopSession:nil];
    [self.session hangUp:nil];

    [[QBRTCClient instance] removeDelegate:self];
    [[QBRTCAudioSession instance] removeDelegate:self];
    [self.TimeOfActiveUser invalidate];
    self.TimeOfActiveUser = nil;
    
    self.reCall = @"0";
    self.parent.reCall = @"0";
    
    [self dismissViewControllerAnimated:NO completion:nil];
}
- (IBAction)actSpeaker {
    if ([QBRTCAudioSession instance].currentAudioDevice == QBRTCAudioDeviceSpeaker) {
        [QBRTCAudioSession instance].currentAudioDevice = QBRTCAudioDeviceReceiver;
        [self.btSpeaker setBackgroundImage:[UIImage imageNamed:@"volumn.png"] forState:UIControlStateNormal];
    } else if ([QBRTCAudioSession instance].currentAudioDevice == QBRTCAudioDeviceReceiver) {
        [QBRTCAudioSession instance].currentAudioDevice = QBRTCAudioDeviceSpeaker;
        [self.btSpeaker setBackgroundImage:[UIImage imageNamed:@"speaker.png"] forState:UIControlStateNormal];
    }
}
- (IBAction)goVideo {
    self.type = @"video";
    [self initView];
}
- (IBAction)goAudio {
    self.type = @"audio";
    [self initView];
}

- (void)initView {
    if ([self.type isEqualToString:@"audio"]) {
        self.videoView.hidden = true;
        self.audioView.hidden = false;
        [QBRTCAudioSession instance].currentAudioDevice = QBRTCAudioDeviceReceiver;
        self.session.localMediaStream.videoTrack.enabled = false;
    } else {
        self.videoView.hidden = false;
        self.audioView.hidden = true;
        [QBRTCAudioSession instance].currentAudioDevice = QBRTCAudioDeviceSpeaker;
        self.session.localMediaStream.videoTrack.enabled = true;
    }
    
    if (!self.isMuteAudio) {
        self.session.localMediaStream.audioTrack.enabled = true;
    } else {
        self.session.localMediaStream.audioTrack.enabled = false;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// QBRTCAudioSessionDelegate

- (void)audioSession:(QBRTCAudioSession *)audioSession didChangeCurrentAudioDevice:(QBRTCAudioDevice)updatedAudioDevice {
    if (updatedAudioDevice == QBRTCAudioDeviceReceiver) {
        [self.btSpeaker setBackgroundImage:[UIImage imageNamed:@"volumn.png"] forState:UIControlStateNormal];
    } else if (updatedAudioDevice == QBRTCAudioDeviceSpeaker) {
        [self.btSpeaker setBackgroundImage:[UIImage imageNamed:@"speaker.png"] forState:UIControlStateNormal];
    }
}

- (void)startTimer {
    if (self.TimeOfActiveUser != nil) {
        int mm = 0;
        int ss = 0;
        ss = self.tt % 60;
        mm = (self.tt - ss) / 60;
        NSString *str_mm = [NSString stringWithFormat:@"%02d", mm];
        NSString *str_ss = [NSString stringWithFormat:@"%02d", ss];
        [self.timer setText:[NSString stringWithFormat:@"%@:%@", str_mm, str_ss]];
        [self.timer1 setText:[NSString stringWithFormat:@"%@:%@", str_mm, str_ss]];
        self.tt ++;
    }
}

#pragma mark -
#pragma mark QBRTCClientDelegate

//- (void)didReceiveNewSession:(QBRTCSession *)session userInfo:(NSDictionary *)userInfo {
//
//    if (self.session) {
//        // we already have a video/audio call session, so we reject another one
//        // userInfo - the custom user information dictionary for the call from caller. May be nil.
//        NSDictionary *userInfo = @{ @"key" : @"value" };
//        [session rejectCall:userInfo];
//        return;
//    }
//    self.session = session;
//}
- (void)sessionDidClose:(QBRTCSession *)session {
    if (session == self.session) {
        
    }
}
- (void)session:(QBRTCSession *)session hungUpByUser:(NSNumber *)userID userInfo:(NSDictionary *)userInfo {
    if ([userInfo isKindOfClass:[NSDictionary class]] && [userInfo objectForKey:@"recall"] != nil) {
        self.reCall = userInfo[@"recall"];
        self.parent.reCall = userInfo[@"recall"];
//        NSTimer *tTimer = [NSTimer scheduledTimerWithTimeInterval:1.5  target:self selector:@selector(initVideo) userInfo:nil repeats:NO];
//        [tTimer fire];
    } else {
        self.reCall = @"0";
        self.parent.reCall = @"0";
    }

    NSLog(@"hangUp by user %@", userID);
    if ([session.initiatorID isEqualToNumber:userID]) {
        [session hangUp:@{}];
    }
}
- (void)session:(QBRTCSession *)session acceptedByUser:(NSNumber *)userID userInfo:(NSDictionary *)userInfo {
    NSLog(@"Accepted by user %@", userID);
    if (![self.reCall isEqualToString:@"1"]) {
        [self startTimer];
    }
}
- (void)session:(QBRTCSession *)session rejectedByUser:(NSNumber *)userID userInfo:(NSDictionary *)userInfo  {
    NSString *message = @"Calling is busy...";
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message  preferredStyle:UIAlertControllerStyleActionSheet];
    [self presentViewController:alert animated:YES completion:nil];
    int duration = 3; // duration in seconds
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, duration * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [alert dismissViewControllerAnimated:YES completion:nil];
    });
    
    NSLog(@"Rejected by user %@", userID);
    [self endCall];
}
- (void)session:(QBRTCSession *)session startedConnectingToUser:(NSNumber *)userID {
    
    NSLog(@"Started connecting to user %@", userID);
}
- (void)session:(QBRTCSession *)session connectionClosedForUser:(NSNumber *)userID {
    
    NSLog(@"Connection is closed for user %@", userID);
    [self endCall];
}
- (void)session:(QBRTCSession *)session connectedToUser:(NSNumber *)userID {
    
    NSLog(@"Connection is established with user %@", userID); 
    if (self.TimeOfActiveUser == nil) {
        self.tt = 0;
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:
                                    [self methodSignatureForSelector: @selector(startTimer)]];
        [invocation setTarget:self];
        [invocation setSelector:@selector(startTimer)];
        self.TimeOfActiveUser = [NSTimer scheduledTimerWithTimeInterval:1 invocation:invocation repeats:YES];
    }
    if (true || [self.reCall isEqualToString:@"1"]) {
        [self initView];
    }
}
//Called in case when receive remote video track from opponent
- (void)session:(QBRTCSession *)session receivedRemoteVideoTrack:(QBRTCVideoTrack *)videoTrack fromUser:(NSNumber *)userID {
    
    // we suppose you have created UIView and set it's class to QBRTCRemoteVideoView class
    // also we suggest you to set view mode to UIViewContentModeScaleAspectFit or
    // UIViewContentModeScaleAspectFill
    [self.remoteVideoView setVideoTrack:videoTrack];
}
- (void)session:(QBRTCSession *)session receivedRemoteAudioTrack:(QBRTCAudioTrack *)audioTrack fromUser:(NSNumber *)userID {
    
    // mute specific user audio track here (for example)
    // you can also always do it later by using '[QBRTCSession remoteAudioTrackWithUserID:]' method
//    audioTrack.enabled = NO;
    if ([self.type isEqualToString:@"audio"]) {
        
    } else {
//        audioTrack.enabled = NO;
    }
}
//=====================

@end
