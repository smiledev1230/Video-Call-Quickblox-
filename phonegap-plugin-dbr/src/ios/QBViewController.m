//
//  QBViewController.m
//  MPC
//
//  Created by Software Engineer on 4/18/18.
//

#import "QBViewController.h"

#import <Quickblox/Quickblox.h>
#import <QuickbloxWebRTC/QuickbloxWebRTC.h>

@interface QBViewController()
<QBRTCClientDelegate>

@property (strong, nonatomic) QBRTCCameraCapture *videoCapture;

@property (nonatomic) IBOutlet QBRTCRemoteVideoView *remoteVideoView;
@property (nonatomic) IBOutlet UIView *localVideoView;
@property (nonatomic) IBOutlet UILabel *userName;
@property (nonatomic) IBOutlet UILabel *timer;
@property (nonatomic) IBOutlet UILabel *userName1;
@property (nonatomic) IBOutlet UILabel *timer1;

@property (nonatomic) IBOutlet UIView *videoView;
@property (nonatomic) IBOutlet UIView *audioView;

@property (weak, nonatomic) UIView *vv;

- (IBAction)cancel;
- (IBAction)flip;

@end

@implementation QBViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [[QBRTCClient instance] addDelegate:self];
    
    if ([self.type isEqualToString:@"audio"]) {
        self.videoView.hidden = true;
        self.audioView.hidden = false;
    } else {
        self.videoView.hidden = false;
        self.audioView.hidden = true;
    }
    [self.userName setText:self.name];
    [self.timer setText:@"Calling..."];
    [self.userName1 setText:self.name];
    [self.timer1 setText:@"Calling..."];
    
#if !(TARGET_IPHONE_SIMULATOR)
    QBRTCVideoFormat *videoFormat = [[QBRTCVideoFormat alloc] init];
    videoFormat.frameRate = 30;
    videoFormat.pixelFormat = QBRTCPixelFormat420f;
    videoFormat.width = 640;
    videoFormat.height = 480;
    
    // QBRTCCameraCapture class used to capture frames using AVFoundation APIs
    self.videoCapture = [[QBRTCCameraCapture alloc] initWithVideoFormat:videoFormat position:AVCaptureDevicePositionFront]; // or AVCaptureDevicePositionBack
    
    // add video capture to session's local media stream
    // from version 2.3 you no longer need to wait for 'initializedLocalMediaStream:' delegate to do it
    self.session.localMediaStream.videoTrack.videoCapture = self.videoCapture;
    
    self.videoCapture.previewLayer.frame = self.localVideoView.bounds;
    [self.videoCapture startSession:nil];
    
    [self.localVideoView.layer insertSublayer:self.videoCapture.previewLayer atIndex:0];
#endif
    // start call
    
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
- (IBAction)cancel {
    [self.videoCapture stopSession:nil];
    [self.session hangUp:nil];
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
- (void)session:(QBRTCSession *)session acceptedByUser:(NSNumber *)userID userInfo:(NSDictionary *)userInfo {
    NSLog(@"Accepted by user %@", userID);
}
- (void)session:(QBRTCSession *)session rejectedByUser:(NSNumber *)userID userInfo:(NSDictionary *)userInfo  {
    NSLog(@"Rejected by user %@", userID);
    [self cancel];
}
- (void)session:(QBRTCSession *)session startedConnectingToUser:(NSNumber *)userID {
    
    NSLog(@"Started connecting to user %@", userID);
}
- (void)session:(QBRTCSession *)session connectionClosedForUser:(NSNumber *)userID {
    
    NSLog(@"Connection is closed for user %@", userID);
    [self cancel];
}
- (void)session:(QBRTCSession *)session connectedToUser:(NSNumber *)userID {
    
    NSLog(@"Connection is established with user %@", userID);
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
        audioTrack.enabled = NO;
    }
}
//=====================

@end
