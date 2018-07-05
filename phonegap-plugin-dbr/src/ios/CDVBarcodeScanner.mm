/*
 * PhoneGap is available under *either* the terms of the modified BSD license *or* the
 * MIT License (2008). See http://opensource.org/licenses/alphabetical for full text.
 *
 * Copyright 2011 Matt Kane. All rights reserved.
 * Copyright (c) 2011, IBM Corporation
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CallKit/CallKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AudioToolbox/AudioToolbox.h>

#import <Quickblox/Quickblox.h>
#import <QuickbloxWebRTC/QuickbloxWebRTC.h>
#import <PushKit/PushKit.h>
#import "QBCore.h"
#import "QBAVCallPermissions.h"
#import "QBViewController.h"
#import "CDVBarcodeScanner.h"

//------------------------------------------------------------------------------
// use the all-in-one version of zxing that we built
//------------------------------------------------------------------------------
//#import "zxing-all-in-one.h"
#import <Cordova/CDVPlugin.h>

// use Dynamsoft Barcode Reader SDK
#import <DynamsoftBarcodeReader/DynamsoftBarcodeReader.h>
#import <DynamsoftBarcodeReader/Barcode.h>

static NSString * const kVoipEvent = @"VOIPCall";
static const NSInteger QBDefaultMaximumCallsPerCallGroup = 1;
static const NSInteger QBDefaultMaximumCallGroups = 1;
//------------------------------------------------------------------------------
// Delegate to handle orientation functions
//------------------------------------------------------------------------------
@protocol CDVBarcodeScannerOrientationDelegate <NSObject>

- (NSUInteger)supportedInterfaceOrientations;
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
- (BOOL)shouldAutorotate;

@end

//------------------------------------------------------------------------------
// Adds a shutter button to the UI, and changes the scan from continuous to
// only performing a scan when you click the shutter button.  For testing.
//------------------------------------------------------------------------------
#define USE_SHUTTER 0

//------------------------------------------------------------------------------
@class CDVbcsProcessor;
@class CDVbcsViewController;

//------------------------------------------------------------------------------
// plugin class
//------------------------------------------------------------------------------
//@interface CDVBarcodeScanner : CDVPlugin {}
//
//@end

@interface CDVBarcodeScanner()
<QBRTCClientDelegate, PKPushRegistryDelegate, CXProviderDelegate>
@property (strong, nonatomic) CXProvider *provider;
@property (assign, nonatomic) UIBackgroundTaskIdentifier backgroundTask;
@property (copy, nonatomic) dispatch_block_t actionCompletionBlock;
@property (copy, nonatomic) dispatch_block_t onAcceptActionBlock;
@property (strong, nonatomic) CXCallController *callController;
@end

//------------------------------------------------------------------------------
// class that does the grunt work
//------------------------------------------------------------------------------
@interface CDVbcsProcessor : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate> {}
@property (nonatomic, retain) CDVBarcodeScanner*           plugin;
@property (nonatomic, retain) NSString*                   callback;
@property (nonatomic, retain) UIViewController*           parentViewController;
@property (nonatomic, retain) CDVbcsViewController*        viewController;
@property (nonatomic, retain) AVCaptureSession*           captureSession;
@property (nonatomic, retain) AVCaptureVideoPreviewLayer* previewLayer;
@property (nonatomic, retain) NSString*                   alternateXib;
@property (nonatomic, retain) NSMutableArray*             results;
@property (nonatomic, retain) NSString*                   formats;
@property (nonatomic)         BOOL                        is1D;
@property (nonatomic)         BOOL                        is2D;
@property (nonatomic)         BOOL                        capturing;
@property (nonatomic)         BOOL                        isFrontCamera;
@property (nonatomic)         BOOL                        isShowFlipCameraButton;
@property (nonatomic)         BOOL                        isFlipped;
@property (nonatomic, retain) BarcodeReader*              barcodeReader;
@property (nonatomic)         long                        barcodeFormat;


- (id)initWithPlugin:(CDVBarcodeScanner*)plugin callback:(NSString*)callback parentViewController:(UIViewController*)parentViewController alterateOverlayXib:(NSString *)alternateXib;
- (void)scanBarcode;
- (void)barcodeScanSucceeded:(NSString*)text format:(NSString*)format;
- (void)barcodeScanFailed:(NSString*)message;
- (void)barcodeScanCancelled;
- (void)openDialog;
- (NSString*)setUpCaptureSession;
- (void)captureOutput:(AVCaptureOutput*)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection*)connection;
- (void)dumpImage:(UIImage*)image;
@end

//------------------------------------------------------------------------------
// Qr encoder processor
//------------------------------------------------------------------------------
@interface CDVqrProcessor: NSObject
@property (nonatomic, retain) CDVBarcodeScanner*          plugin;
@property (nonatomic, retain) NSString*                   callback;
@property (nonatomic, retain) NSString*                   stringToEncode;
@property                     NSInteger                   size;

- (id)initWithPlugin:(CDVBarcodeScanner*)plugin callback:(NSString*)callback stringToEncode:(NSString*)stringToEncode;
- (void)generateImage;
@end

//------------------------------------------------------------------------------
// view controller for the ui
//------------------------------------------------------------------------------
@interface CDVbcsViewController : UIViewController <CDVBarcodeScannerOrientationDelegate> {}
@property (nonatomic, retain) CDVbcsProcessor*  processor;
@property (nonatomic, retain) NSString*        alternateXib;
@property (nonatomic)         BOOL             shutterPressed;
@property (nonatomic, retain) IBOutlet UIView* overlayView;
// unsafe_unretained is equivalent to assign - used to prevent retain cycles in the property below
@property (nonatomic, unsafe_unretained) id orientationDelegate;

- (id)initWithProcessor:(CDVbcsProcessor*)processor alternateOverlay:(NSString *)alternateXib;
- (void)startCapturing;
- (UIView*)buildOverlayView;
- (UIImage*)buildReticleImage;
- (void)shutterButtonPressed;
- (IBAction)cancelButtonPressed:(id)sender;

@end

//------------------------------------------------------------------------------
// plugin class
//------------------------------------------------------------------------------
@implementation CDVBarcodeScanner

//--------------------------------------------------------------------------
- (NSString*)isScanNotPossible {
    NSString* result = nil;

    Class aClass = NSClassFromString(@"AVCaptureSession");
    if (aClass == nil) {
        return @"AVFoundation Framework not available";
    }

    return result;
}

//------------------------- quickblox -----------------------------------------
- (void)initQB:(CDVInvokedUrlCommand*)command {
    
    NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
    CXProviderConfiguration *config = [[CXProviderConfiguration alloc] initWithLocalizedName:appName];
    config.supportsVideo = YES;
    config.maximumCallsPerCallGroup = QBDefaultMaximumCallsPerCallGroup;
    config.maximumCallGroups = QBDefaultMaximumCallGroups;
    config.supportedHandleTypes = [NSSet setWithObjects:@(CXHandleTypeGeneric), @(CXHandleTypePhoneNumber), nil];
    config.iconTemplateImageData = UIImagePNGRepresentation([UIImage imageNamed:@"CallKitLogo"]);
    config.ringtoneSound = @"ringtone.wav";
    
    self.provider = [[CXProvider alloc] initWithConfiguration:config];
    [self.provider setDelegate:self queue:nil];
    
    self.callController = [[CXCallController alloc] initWithQueue:dispatch_get_main_queue()];
    
    _backgroundTask = UIBackgroundTaskInvalid;
    
    // init Quickblox
    
    const NSTimeInterval kQBAnswerTimeInterval = 120.f;
    const NSTimeInterval kQBDialingTimeInterval = 5.f;
    
//    [QBSettings setAccountKey:@"7yvNe17TnjNUqDoPwfqp"];
//    [QBSettings setApplicationID:39854];
//    [QBSettings setAuthKey:@"JtensAa9y4AM5Yk"];
//    [QBSettings setAuthSecret:@"AsDFwwwxpr3LN5w"];
    [QBSettings setAccountKey:@"yxb6rbxXh_hTVchCoV6e"];
    [QBSettings setApplicationID:69170];
    [QBSettings setAuthKey:@"K6-WFcUCRHcGtwH"];
    [QBSettings setAuthSecret:@"Qbs9Gk55RT3cVkL"];
    
    [QBSettings setLogLevel:QBLogLevelDebug];
    [QBSettings enableXMPPLogging];
    
    [QBRTCConfig setAnswerTimeInterval:kQBAnswerTimeInterval];
    [QBRTCConfig setDialingTimeInterval:kQBDialingTimeInterval];
    [QBRTCConfig setStatsReportTimeInterval:1.f];
    
    [QBRTCClient initializeRTC];
}
- (void)loginQB:(CDVInvokedUrlCommand*)command {
    NSString*       callback;
    callback = command.callbackId;
    NSDictionary* options = command.arguments.count == 0 ? [NSNull null] : [command.arguments objectAtIndex:0];
    
    if ([options isKindOfClass:[NSNull class]]) {
        options = [NSDictionary dictionary];
    }
    NSString* userId = options[@"userId"];
    
    if (0 && Core.currentUser) {
        
        [Core loginWithCurrentUser:callback plugin:self];
    }
    else {
        
        [Core signUpWithFullName:userId
                        roomName:userId
                        callback: callback plugin:self];
    }
    
    [[QBRTCClient instance] addDelegate:self];
}
- (void)logoutQB:(CDVInvokedUrlCommand*)command {
    [Core logout1];
}

// --- return login info to cordova ---
- (void)returnLoginQB:(NSString*)userId callback:(NSString*)callback{
    self.voipRegistry = [[PKPushRegistry alloc] initWithQueue:dispatch_get_main_queue()];
    self.voipRegistry.delegate = self;
    self.voipRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
    
    NSMutableDictionary* resultDict = [[[NSMutableDictionary alloc] init] autorelease];
    [resultDict setObject:userId forKey:@"userId"];
    
    CDVPluginResult* result = [CDVPluginResult
                               resultWithStatus: CDVCommandStatus_OK
                               messageAsDictionary:resultDict
                               ];
    
    [[self commandDelegate] sendPluginResult:result callbackId:callback];
}

- (void)endCallQB:(CDVInvokedUrlCommand*)command {
    [self.session hangUp:nil];
}
- (void)audioCallQB:(CDVInvokedUrlCommand*)command {
    NSDictionary* options = command.arguments.count == 0 ? [NSNull null] : [command.arguments objectAtIndex:0];
    
    if ([options isKindOfClass:[NSNull class]]) {
        options = [NSDictionary dictionary];
    }
    [self callWithConferenceType:QBRTCConferenceTypeAudio userInfo:options];
}
- (void)videoCallQB:(CDVInvokedUrlCommand*)command {
    NSDictionary* options = command.arguments.count == 0 ? [NSNull null] : [command.arguments objectAtIndex:0];
    
    if ([options isKindOfClass:[NSNull class]]) {
        options = [NSDictionary dictionary];
    }
    [self callWithConferenceType:QBRTCConferenceTypeVideo userInfo:options];
}
- (void)callWithConferenceType:(QBRTCConferenceType)conferenceType userInfo:(NSDictionary*)options{
    NSString* userId = options[@"userId"];
//    NSString* login = options[@"login"];
    NSString* answer = options[@"answer"];
    NSInteger number_userId = [userId integerValue];
    NSNumber *myNumber = [NSNumber numberWithInteger:number_userId];
//    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
//    f.numberStyle = NSNumberFormatterDecimalStyle;
//    NSNumber *myNumber = [f numberFromString:userId];
    
    NSArray <NSNumber *> *opponentsIDs;
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:1];
    [result addObject:myNumber];
    opponentsIDs = result;
    
    NSString *type = @"audio";
    if (conferenceType == QBRTCConferenceTypeVideo) {
        type = @"video";
    }
    conferenceType = QBRTCConferenceTypeVideo;
    
    QBRTCSession *newSession = nil;
    if ([answer isEqualToString:@"0"]) {
        newSession = [[QBRTCClient instance] createNewSessionWithOpponents:opponentsIDs
                                                                  withConferenceType:conferenceType];
        NSDictionary *userInfo = options;
        
        self.session = newSession;
        [self.session startCall:userInfo];
    } else {
        NSDictionary *userInfo = options;
        [self.session acceptCall:userInfo];
    }
    
    QBViewController *qbView = [[QBViewController alloc] init];
    qbView.session = self.session;
    qbView.type = type;
    qbView.answer = answer;
    qbView.name = options[@"name1"];
    qbView.parent = self;
    self.qbView = qbView;
    self.nav = [[UINavigationController alloc] initWithRootViewController:qbView];
    self.nav.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    self.nav.navigationBarHidden = true;
    [self.viewController presentViewController:self.nav animated:NO completion:nil];
    
    // send voip push
    NSDictionary *payload = @{
                              @"message"  : [NSString stringWithFormat:@"%@ is calling...", @"MPC"],
                              @"ios_voip" : @"1",
                              kVoipEvent  : @"1",
                              };
    NSData *data =
    [NSJSONSerialization dataWithJSONObject:payload
                                    options:NSJSONWritingPrettyPrinted
                                      error:nil];
    NSString *message =
    [[NSString alloc] initWithData:data
                          encoding:NSUTF8StringEncoding];
    
    QBMEvent *event = [QBMEvent event];
    event.notificationType = QBMNotificationTypePush;
    event.usersIDs = [opponentsIDs componentsJoinedByString:@","];
    event.type = QBMEventTypeOneShot;
    event.message = message;
    
    [QBRequest createEvent:event
              successBlock:^(QBResponse *response, NSArray<QBMEvent *> *events) {
                  NSLog(@"Send voip push - Success");
              } errorBlock:^(QBResponse * _Nonnull response) {
                  NSLog(@"Send voip push - Error");
              }];
}
- (void)acceptCallQB:(CDVInvokedUrlCommand*)command {
    NSDictionary* options = command.arguments.count == 0 ? [NSNull null] : [command.arguments objectAtIndex:0];
    
    if ([options isKindOfClass:[NSNull class]]) {
        options = [NSDictionary dictionary];
    }
    
}
- (void)setQBHandler:(CDVInvokedUrlCommand*)command {
    self.notficationReceivedCallbackId11 = command.callbackId;
}
- (void)setQBHandlerEnd:(CDVInvokedUrlCommand*)command {
    self.notficationEndReceivedCallbackId11 = command.callbackId;
}
- (void)setQBHandlerAccept:(CDVInvokedUrlCommand*)command {
    self.notficationAcceptReceivedCallbackId11 = command.callbackId;
}
- (void)succesCallback11:(NSString *)callbackId  userInfo:(NSDictionary *)userInfo{
//    NSMutableDictionary* data = [[[NSMutableDictionary alloc] init] autorelease];
//    [data setObject:@"userId" forKey:@"userId"];
    CDVPluginResult* commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:userInfo];
    commandResult.keepCallback = @1;
    [[self commandDelegate] sendPluginResult:commandResult callbackId:callbackId];
}

- (BOOL)isCallKitAvailable {
    static BOOL callKitAvailable = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
#if TARGET_IPHONE_SIMULATOR
        callKitAvailable = NO;
#else
        callKitAvailable = [UIDevice currentDevice].systemVersion.integerValue >= 10;
#endif
    });
    return callKitAvailable;
}

// MARK: - PKPushRegistryDelegate protocol

- (void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials:(PKPushCredentials *)pushCredentials forType:(PKPushType)type {
    
    //  New way, only for updated backend
    NSString *deviceIdentifier = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    
    QBMSubscription *subscription = [QBMSubscription subscription];
    subscription.notificationChannel = QBMNotificationChannelAPNSVOIP;
    subscription.deviceUDID = deviceIdentifier;
    subscription.deviceToken = [self.voipRegistry pushTokenForType:PKPushTypeVoIP];
    
    [QBRequest createSubscription:subscription successBlock:^(QBResponse *response, NSArray *objects) {
        NSLog(@"Create Subscription request - Success");
    } errorBlock:^(QBResponse *response) {
        NSLog(@"Create Subscription request - Error");
    }];
}
- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(PKPushType)type {
    if ([self isCallKitAvailable]) {
        if ([payload.dictionaryPayload objectForKey:kVoipEvent] != nil) {
            UIApplication *application = [UIApplication sharedApplication];
            if (application.applicationState == UIApplicationStateBackground
                && _backgroundTask == UIBackgroundTaskInvalid) {
                _backgroundTask = [application beginBackgroundTaskWithExpirationHandler:^{
                    [application endBackgroundTask:_backgroundTask];
                    _backgroundTask = UIBackgroundTaskInvalid;
                }];
            }
        }
    }
}
- (void)endCallWithUUID:(NSUUID *)uuid completion:(dispatch_block_t)completion {
    if (_session == nil) {
        return;
    }
    if (uuid == nil) {
        return;
    }
    
    CXEndCallAction *action = [[CXEndCallAction alloc] initWithCallUUID:uuid];
    CXTransaction *transaction = [[CXTransaction alloc] initWithAction:action];
    
    dispatchOnMainThread(^{
        [self requestTransaction:transaction completion:nil];
    });
    
    if (completion != nil) {
        _actionCompletionBlock = completion;
    }
}
- (void)requestTransaction:(CXTransaction *)transaction completion:(void (^)(BOOL))completion {
    [_callController requestTransaction:transaction completion:^(NSError *error) {
        if (error != nil) {
            NSLog(@"[CallKitManager] Error: %@", error);
        }
        if (completion != nil) {
            completion(error == nil);
        }
    }];
}
#pragma mark -
#pragma mark QBRTCClientDelegate

- (void)sessionDidClose:(QBRTCSession *)session {
    if (session == self.session) {
//        UIApplication *application = [UIApplication sharedApplication];
//        if (application.applicationState == UIApplicationStateBackground) {
            [self endCallWithUUID:_callUUID completion:nil];
//        }
    }
}
- (void)session:(QBRTCSession *)session connectionClosedForUser:(NSNumber *)userID {
    
    NSLog(@"Connection is closed for user %@", userID);
    NSMutableDictionary* userInfo = [[[NSMutableDictionary alloc] init] autorelease];
    [userInfo setObject:userID forKey:@"userId"];
    [self succesCallback11:self.notficationEndReceivedCallbackId11 userInfo:userInfo];
    
    UIApplication *application = [UIApplication sharedApplication];
    if (application.applicationState == UIApplicationStateBackground) {
        [self endCallWithUUID:_callUUID completion:nil];
    }
}
- (void)session:(QBRTCSession *)session rejectedByUser:(NSNumber *)userID userInfo:(NSDictionary *)userInfo  {
    NSLog(@"Rejected by user %@", userID);
//    [self cancel];
}
- (void)didReceiveNewSession:(QBRTCSession *)session userInfo:(NSDictionary *)userInfo {
    
    if (self.session) {
        // we already have a video/audio call session, so we reject another one
        // userInfo - the custom user information dictionary for the call from caller. May be nil.
//        NSDictionary *userInfo = @{ @"key" : @"value" };
//        [session rejectCall:userInfo];
//        return;
    }
    UIApplication *application = [UIApplication sharedApplication];
    
    self.session = session;
    
    if ([self.reCall isEqualToString:@"1"]) {
        self.qbView.session = session;
        [self.session acceptCall:userInfo];
        [self.qbView updateVideo];
        return;
    }
    if (application.applicationState != UIApplicationStateBackground) {
        [self succesCallback11:self.notficationReceivedCallbackId11 userInfo:userInfo];
    }
    
    self.userInfo = userInfo;
    
    if (application.applicationState == UIApplicationStateBackground && ![self.reCall isEqualToString:@"1"]) {
        self.callUUID = [NSUUID UUID];
        NSMutableArray *opponentIDs = [@[session.initiatorID] mutableCopy];
        for (NSNumber *userID in session.opponentsIDs) {
            if ([userID integerValue] != [QBCore instance].currentUser.ID) {
                [opponentIDs addObject:userID];
            }
        }
        NSString *name = userInfo[@"name"];
        NSString *type = userInfo[@"type"];
        [self reportIncomingCallWithUserIDs:[opponentIDs copy] session:session uName:name uType:type uuid:self.callUUID onAcceptAction:^{
            
             [self.session acceptCall:userInfo];
    
             QBViewController *qbView = [[QBViewController alloc] init];
             qbView.session = self.session;
             qbView.type = userInfo[@"type"];
             qbView.answer = @"1";
             qbView.name = name;
             self.qbView = qbView;
             self.nav = [[UINavigationController alloc] initWithRootViewController:qbView];
             self.nav.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
             self.nav.navigationBarHidden = true;
             [self.viewController presentViewController:self.nav animated:NO completion:nil];
            
        } completion:nil];
    }
}
- (void)reportIncomingCallWithUserIDs:(NSArray *)userIDs session:(QBRTCSession *)session uName:(NSString *)uName uType:(NSString *)uType uuid:(NSUUID *)uuid onAcceptAction:(dispatch_block_t)onAcceptAction completion:(void (^)(BOOL))completion {
    NSLog(@"[CallKitManager] Report incoming call %@", uuid);

    _session = session;
    _onAcceptActionBlock = onAcceptAction;
    
    NSString *callerName = nil;
    CXCallUpdate *update = [[CXCallUpdate alloc] init];
    update.remoteHandle = [self handleForUserIDs:userIDs outCallerName:&callerName];
    update.localizedCallerName = uName;
    update.supportsHolding = NO;
    update.supportsGrouping = NO;
    update.supportsUngrouping = NO;
    update.supportsDTMF = NO;
    update.hasVideo = [uType isEqualToString:@"video"];
    
    [_provider reportNewIncomingCallWithUUID:uuid update:update completion:^(NSError * _Nullable error) {
        BOOL silent = ([error.domain isEqualToString:CXErrorDomainIncomingCall] && error.code == CXErrorCodeIncomingCallErrorFilteredByDoNotDisturb);
        dispatchOnMainThread(^{
            if (completion != nil) {
                completion(silent);
            }
        });
    }];
}

static inline void dispatchOnMainThread(dispatch_block_t block) {
    if ([NSThread isMainThread]) {
        block();
    }
    else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

- (CXHandle *)handleForUserIDs:(NSArray *)userIDs outCallerName:(NSString **)outCallerName {
    // handle user from whatever database here

    return [[CXHandle alloc] initWithType:CXHandleTypeGeneric value:[userIDs componentsJoinedByString:@", "]];
}

// MARK: - CXProviderDelegate protocol

- (void)providerDidReset:(CXProvider *)__unused provider {
    NSLog(@"CXProvider - providerDidReset");
}

- (void)provider:(CXProvider *)__unused provider performStartCallAction:(CXStartCallAction *)action {
    NSLog(@"CXProvider - performStartCallAction");
}

- (void)provider:(CXProvider *)__unused provider performAnswerCallAction:(CXAnswerCallAction *)action {
    NSLog(@"CXProvider - performAnswerCallAction");
    if (_session == nil) {
        [action fail];
        return;
    }
    dispatchOnMainThread(^{
        [self.session acceptCall:self.userInfo];
        [action fulfill];
        
        QBViewController *qbView = [[QBViewController alloc] init];
        qbView.session = self.session;
        qbView.type = self.userInfo[@"type"];
        qbView.answer = @"1";
        qbView.name = self.userInfo[@"name1"];
        self.qbView = qbView;
        self.nav = [[UINavigationController alloc] initWithRootViewController:qbView];
        self.nav.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        self.nav.navigationBarHidden = true;
        [self.viewController presentViewController:self.nav animated:NO completion:nil];
        
        [self succesCallback11:self.notficationAcceptReceivedCallbackId11 userInfo:self.userInfo];

//        if (_onAcceptActionBlock != nil) {
//            _onAcceptActionBlock();
//            _onAcceptActionBlock = nil;
//        }
    });
}

- (void)provider:(CXProvider *)__unused provider performEndCallAction:(CXEndCallAction *)action {
    NSLog(@"CXProvider - EndCallAction");
    if (_session == nil) {
        [action fail];
        return;
    }
    QBRTCSession *session = _session;
    _session = nil;
    
    dispatchOnMainThread(^{
        
        [session rejectCall:nil];

        [action fulfillWithDateEnded:[NSDate date]];
        
        if (_actionCompletionBlock != nil) {
            _actionCompletionBlock();
            _actionCompletionBlock = nil;
        }
    });
}

- (void)provider:(CXProvider *)__unused provider performSetMutedCallAction:(CXSetMutedCallAction *)action {
    
}

- (void)provider:(CXProvider *)__unused provider didActivateAudioSession:(AVAudioSession *)audioSession {
    NSLog(@"[CallKitManager] Activated audio session.");
    QBRTCAudioSession *rtcAudioSession = [QBRTCAudioSession instance];
    [rtcAudioSession audioSessionDidActivate:audioSession];
    // enabling audio now
    rtcAudioSession.audioEnabled = YES;
    // enabling local mic recording in recorder (if recorder is active) as of interruptions are over now
    _session.recorder.localAudioEnabled = YES;
}

- (void)provider:(CXProvider *)provider didDeactivateAudioSession:(AVAudioSession *)audioSession {
    NSLog(@"[CallKitManager] Dectivated audio session.");
    [[QBRTCAudioSession instance] audioSessionDidDeactivate:audioSession];
    // deinitializing audio session after iOS deactivated it for us
    QBRTCAudioSession *session = [QBRTCAudioSession instance];
    if (session.isInitialized) {
        NSLog(@"Deinitializing session in CallKit callback.");
        [session deinitialize];
    }
}

//==========================================================================
- (void)scan:(CDVInvokedUrlCommand*)command {
    CDVbcsProcessor* processor;
    NSString*       callback;
    NSString*       capabilityError;

    callback = command.callbackId;

    NSDictionary* options = command.arguments.count == 0 ? [NSNull null] : [command.arguments objectAtIndex:0];

    if ([options isKindOfClass:[NSNull class]]) {
      options = [NSDictionary dictionary];
    }
    BOOL preferFrontCamera = [options[@"preferFrontCamera"] boolValue];
    BOOL showFlipCameraButton = [options[@"showFlipCameraButton"] boolValue];
    // We allow the user to define an alternate xib file for loading the overlay.
    NSString *overlayXib = [options objectForKey:@"overlayXib"];

    capabilityError = [self isScanNotPossible];
    if (capabilityError) {
        [self returnError:capabilityError callback:callback];
        return;
    }

    processor = [[CDVbcsProcessor alloc]
                 initWithPlugin:self
                 callback:callback
                 parentViewController:self.viewController
                 alterateOverlayXib:overlayXib
                 ];
    // queue [processor scanBarcode] to run on the event loop

    if (preferFrontCamera) {
      processor.isFrontCamera = true;
    }

    if (showFlipCameraButton) {
      processor.isShowFlipCameraButton = true;
    }

    processor.formats = options[@"formats"];

    [processor performSelector:@selector(scanBarcode) withObject:nil afterDelay:0];
}

//--------------------------------------------------------------------------
- (void)encode:(CDVInvokedUrlCommand*)command {
    if([command.arguments count] < 1)
        [self returnError:@"Too few arguments!" callback:command.callbackId];

    CDVqrProcessor* processor;
    NSString*       callback;
    callback = command.callbackId;

    processor = [[CDVqrProcessor alloc]
                 initWithPlugin:self
                 callback:callback
                 stringToEncode: command.arguments[0][@"data"]
                 ];

    [processor retain];
    [processor retain];
    [processor retain];
    // queue [processor generateImage] to run on the event loop
    [processor performSelector:@selector(generateImage) withObject:nil afterDelay:0];
}

- (void)returnImage:(NSString*)filePath format:(NSString*)format callback:(NSString*)callback{
    NSMutableDictionary* resultDict = [[[NSMutableDictionary alloc] init] autorelease];
    [resultDict setObject:format forKey:@"format"];
    [resultDict setObject:filePath forKey:@"file"];

    CDVPluginResult* result = [CDVPluginResult
                               resultWithStatus: CDVCommandStatus_OK
                               messageAsDictionary:resultDict
                               ];

    [[self commandDelegate] sendPluginResult:result callbackId:callback];
}

//--------------------------------------------------------------------------
- (void)returnSuccess:(NSString*)scannedText format:(NSString*)format cancelled:(BOOL)cancelled flipped:(BOOL)flipped callback:(NSString*)callback{
    NSNumber* cancelledNumber = [NSNumber numberWithInt:(cancelled?1:0)];

    NSMutableDictionary* resultDict = [[NSMutableDictionary alloc] init];
    [resultDict setObject:scannedText     forKey:@"text"];
    [resultDict setObject:format          forKey:@"format"];
    [resultDict setObject:cancelledNumber forKey:@"cancelled"];

    CDVPluginResult* result = [CDVPluginResult
                               resultWithStatus: CDVCommandStatus_OK
                               messageAsDictionary: resultDict
                               ];
    [self.commandDelegate sendPluginResult:result callbackId:callback];
}

//--------------------------------------------------------------------------
- (void)returnError:(NSString*)message callback:(NSString*)callback {
    CDVPluginResult* result = [CDVPluginResult
                               resultWithStatus: CDVCommandStatus_ERROR
                               messageAsString: message
                               ];

    [self.commandDelegate sendPluginResult:result callbackId:callback];
}

@end

//------------------------------------------------------------------------------
// class that does the grunt work
//------------------------------------------------------------------------------
@implementation CDVbcsProcessor

@synthesize plugin               = _plugin;
@synthesize callback             = _callback;
@synthesize parentViewController = _parentViewController;
@synthesize viewController       = _viewController;
@synthesize captureSession       = _captureSession;
@synthesize previewLayer         = _previewLayer;
@synthesize alternateXib         = _alternateXib;
@synthesize is1D                 = _is1D;
@synthesize is2D                 = _is2D;
@synthesize capturing            = _capturing;
@synthesize results              = _results;
@synthesize barcodeReader        = _barcodeReader;
@synthesize barcodeFormat        = _barcodeFormat;

SystemSoundID _soundFileObject;

//--------------------------------------------------------------------------
- (id)initWithPlugin:(CDVBarcodeScanner*)plugin
            callback:(NSString*)callback
parentViewController:(UIViewController*)parentViewController
  alterateOverlayXib:(NSString *)alternateXib {
    self = [super init];
    if (!self) return self;

    self.plugin               = plugin;
    self.callback             = callback;
    self.parentViewController = parentViewController;
    self.alternateXib         = alternateXib;

    self.is1D      = YES;
    self.is2D      = YES;
    self.capturing = NO;
    self.results = [NSMutableArray new];

    CFURLRef soundFileURLRef  = CFBundleCopyResourceURL(CFBundleGetMainBundle(), CFSTR("CDVBarcodeScanner.bundle/beep"), CFSTR ("caf"), NULL);
    AudioServicesCreateSystemSoundID(soundFileURLRef, &_soundFileObject);
    
    self.barcodeReader = [[BarcodeReader alloc] initWithLicense:@"license"];
    self.barcodeFormat = Barcode.OneD | Barcode.PDF417 | Barcode.QR_CODE;

    return self;
}

//--------------------------------------------------------------------------
- (void)dealloc {
    self.plugin = nil;
    self.callback = nil;
    self.parentViewController = nil;
    self.viewController = nil;
    self.captureSession = nil;
    self.previewLayer = nil;
    self.alternateXib = nil;
    self.results = nil;

    self.capturing = NO;

    AudioServicesRemoveSystemSoundCompletion(_soundFileObject);
    AudioServicesDisposeSystemSoundID(_soundFileObject);

    [super dealloc];
}

//--------------------------------------------------------------------------
- (void)scanBarcode {

//    self.captureSession = nil;
//    self.previewLayer = nil;
    NSString* errorMessage = [self setUpCaptureSession];
    if (errorMessage) {
        [self barcodeScanFailed:errorMessage];
        return;
    }

    self.viewController = [[CDVbcsViewController alloc] initWithProcessor: self alternateOverlay:self.alternateXib];
    // here we set the orientation delegate to the MainViewController of the app (orientation controlled in the Project Settings)
    self.viewController.orientationDelegate = self.plugin.viewController;

    // delayed [self openDialog];
    [self performSelector:@selector(openDialog) withObject:nil afterDelay:1];
}

//--------------------------------------------------------------------------
- (void)openDialog {
    [self.parentViewController
     presentViewController:self.viewController
     animated:YES completion:nil
     ];
}

//--------------------------------------------------------------------------
- (void)barcodeScanDone:(void (^)(void))callbackBlock {
    self.capturing = NO;
    [self.captureSession stopRunning];
    [self.parentViewController dismissViewControllerAnimated:YES completion:callbackBlock];
    
    // viewcontroller holding onto a reference to us, release them so they
    // will release us
    self.viewController = nil;
}

//--------------------------------------------------------------------------
- (BOOL)checkResult:(NSString *)result {
    [self.results addObject:result];

    NSInteger treshold = 7;

    if (self.results.count > treshold) {
        [self.results removeObjectAtIndex:0];
    }

    if (self.results.count < treshold)
    {
        return NO;
    }

    BOOL allEqual = YES;
    NSString *compareString = [self.results objectAtIndex:0];

    for (NSString *aResult in self.results)
    {
        if (![compareString isEqualToString:aResult])
        {
            allEqual = NO;
            //NSLog(@"Did not fit: %@",self.results);
            break;
        }
    }

    return allEqual;
}

//--------------------------------------------------------------------------
- (void)barcodeScanSucceeded:(NSString*)text format:(NSString*)format {
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self barcodeScanDone:^{
            [self.plugin returnSuccess:text format:format cancelled:FALSE flipped:FALSE callback:self.callback];
        }];
        AudioServicesPlaySystemSound(_soundFileObject);
    });
}

//--------------------------------------------------------------------------
- (void)barcodeScanFailed:(NSString*)message {
    [self barcodeScanDone:^{
        [self.plugin returnError:message callback:self.callback];
    }];
}

//--------------------------------------------------------------------------
- (void)barcodeScanCancelled {
    [self barcodeScanDone:^{
        [self.plugin returnSuccess:@"" format:@"" cancelled:TRUE flipped:self.isFlipped callback:self.callback];
    }];
    if (self.isFlipped) {
        self.isFlipped = NO;
    }
}

- (void)flipCamera {
    self.isFlipped = YES;
    self.isFrontCamera = !self.isFrontCamera;
    [self barcodeScanDone];
    if (self.isFlipped) {
      self.isFlipped = NO;
    }
    [self performSelector:@selector(scanBarcode) withObject:nil afterDelay:0.1];
}

//--------------------------------------------------------------------------
- (NSString*)setUpCaptureSession {
    NSError* error = nil;

    AVCaptureSession* captureSession = [[AVCaptureSession alloc] init];
    self.captureSession = captureSession;

       AVCaptureDevice* __block device = nil;
    if (self.isFrontCamera) {

        NSArray* devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        [devices enumerateObjectsUsingBlock:^(AVCaptureDevice *obj, NSUInteger idx, BOOL *stop) {
            if (obj.position == AVCaptureDevicePositionFront) {
                device = obj;
            }
        }];
    } else {
        device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if (!device) return @"unable to obtain video capture device";

    }


    AVCaptureDeviceInput* input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (!input) return @"unable to obtain video capture device input";

    AVCaptureVideoDataOutput* output = [[AVCaptureVideoDataOutput alloc] init];
    if (!output) return @"unable to obtain video capture output";

    NSDictionary* videoOutputSettings = [NSDictionary
                                         dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8PlanarFullRange]
                                         forKey:(id)kCVPixelBufferPixelFormatTypeKey
                                         ];

    output.alwaysDiscardsLateVideoFrames = YES;
//    output.videoSettings = videoOutputSettings;
    [output setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    [output setSampleBufferDelegate:self queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)];
    
//    [output setSampleBufferDelegate:self queue:dispatch_queue_create("dbrCameraQueue", NULL)];

    if ([captureSession canSetSessionPreset:AVCaptureSessionPresetHigh]) {
      captureSession.sessionPreset = AVCaptureSessionPresetHigh;
    } else if ([captureSession canSetSessionPreset:AVCaptureSessionPresetMedium]) {
      captureSession.sessionPreset = AVCaptureSessionPresetMedium;
    } else {
      return @"unable to preset high nor medium quality video capture";
    }

    if ([captureSession canAddInput:input]) {
        [captureSession addInput:input];
    }
    else {
        return @"unable to add video capture device input to session";
    }

    if ([captureSession canAddOutput:output]) {
        [captureSession addOutput:output];
    }
    else {
        return @"unable to add video capture output to session";
    }

    // setup capture preview layer
    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:captureSession];

    // run on next event loop pass [captureSession startRunning]
    [captureSession performSelector:@selector(startRunning) withObject:nil afterDelay:0];

    return nil;
}

//--------------------------------------------------------------------------
// this method gets sent the captured frames
//--------------------------------------------------------------------------
- (void)captureOutput:(AVCaptureOutput*)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection*)connection {

    if (!self.capturing) return;

#if USE_SHUTTER
    if (!self.viewController.shutterPressed) return;
    self.viewController.shutterPressed = NO;

    UIView* flashView = [[UIView alloc] initWithFrame:self.viewController.view.frame];
    [flashView setBackgroundColor:[UIColor whiteColor]];
    [self.viewController.view.window addSubview:flashView];

    [UIView
     animateWithDuration:.4f
     animations:^{
         [flashView setAlpha:0.f];
     }
     completion:^(BOOL finished){
         [flashView removeFromSuperview];
     }
     ];

    //         [self dumpImage: [[self getImageFromSample:sampleBuffer] autorelease]];
#endif


//    using namespace zxing;
//
//    // LuminanceSource is pretty dumb; we have to give it a pointer to
//    // a byte array, but then can't get it back out again.  We need to
//    // get it back to free it.  Saving it in imageBytes.
//    uint8_t* imageBytes;
//
//    //        NSTimeInterval timeStart = [NSDate timeIntervalSinceReferenceDate];
//
//    try {
//        NSArray *supportedFormats = nil;
//        if (self.formats != nil) {
//            supportedFormats = [self.formats componentsSeparatedByString:@","];
//        }
//        DecodeHints decodeHints;
//        if (supportedFormats == nil || [supportedFormats containsObject:[self formatStringFrom:BarcodeFormat_QR_CODE]]) {
//            decodeHints.addFormat(BarcodeFormat_QR_CODE);
//        }
//        if (supportedFormats == nil || [supportedFormats containsObject:[self formatStringFrom:BarcodeFormat_CODE_128]]) {
//            decodeHints.addFormat(BarcodeFormat_CODE_128);
//        }
//        if (supportedFormats == nil || [supportedFormats containsObject:[self formatStringFrom:BarcodeFormat_CODE_39]]) {
//            decodeHints.addFormat(BarcodeFormat_CODE_39);
//        }
//        if (supportedFormats == nil || [supportedFormats containsObject:[self formatStringFrom:BarcodeFormat_DATA_MATRIX]]) {
//            decodeHints.addFormat(BarcodeFormat_DATA_MATRIX);
//        }
//        if (supportedFormats == nil || [supportedFormats containsObject:[self formatStringFrom:BarcodeFormat_UPC_E]]) {
//            decodeHints.addFormat(BarcodeFormat_UPC_E);
//        }
//        if (supportedFormats == nil || [supportedFormats containsObject:[self formatStringFrom:BarcodeFormat_UPC_A]]) {
//            decodeHints.addFormat(BarcodeFormat_UPC_A);
//        }
//        if (supportedFormats == nil || [supportedFormats containsObject:[self formatStringFrom:BarcodeFormat_EAN_8]]) {
//            decodeHints.addFormat(BarcodeFormat_EAN_8);
//        }
//        if (supportedFormats == nil || [supportedFormats containsObject:[self formatStringFrom:BarcodeFormat_EAN_13]]) {
//            decodeHints.addFormat(BarcodeFormat_EAN_13);
//        }
////        decodeHints.addFormat(BarcodeFormat_ITF);   causing crashes
//
//        // here's the meat of the decode process
//        Ref<LuminanceSource>   luminanceSource   ([self getLuminanceSourceFromSample: sampleBuffer imageBytes:&imageBytes]);
//        //            [self dumpImage: [[self getImageFromLuminanceSource:luminanceSource] autorelease]];
//        Ref<Binarizer>         binarizer         (new HybridBinarizer(luminanceSource));
//        Ref<BinaryBitmap>      bitmap            (new BinaryBitmap(binarizer));
//        Ref<MultiFormatReader> reader            (new MultiFormatReader());
//        Ref<Result>            result            (reader->decode(bitmap, decodeHints));
//        Ref<String>            resultText        (result->getText());
//        BarcodeFormat          formatVal =       result->getBarcodeFormat();
//        NSString*              format    =       [self formatStringFrom:formatVal];
//
//
//        const char* cString      = resultText->getText().c_str();
//        NSString*   resultString = [[NSString alloc] initWithCString:cString encoding:NSUTF8StringEncoding];
//
//        if ([self checkResult:resultString]) {
//            [self barcodeScanSucceeded:resultString format:format];
//        }
//    }
//    catch (zxing::ReaderException &rex) {
//        //            NSString *message = [[[NSString alloc] initWithCString:rex.what() encoding:NSUTF8StringEncoding] autorelease];
//        //            NSLog(@"decoding: ReaderException: %@", message);
//    }
//    catch (zxing::IllegalArgumentException &iex) {
//        //            NSString *message = [[[NSString alloc] initWithCString:iex.what() encoding:NSUTF8StringEncoding] autorelease];
//        //            NSLog(@"decoding: IllegalArgumentException: %@", message);
//    }
//    catch (...) {
//        //            NSLog(@"decoding: unknown exception");
//        //            [self barcodeScanFailed:@"unknown exception decoding barcode"];
//    }
//
//    //        NSTimeInterval timeElapsed  = [NSDate timeIntervalSinceReferenceDate] - timeStart;
//    //        NSLog(@"decoding completed in %dms", (int) (timeElapsed * 1000));
//
//    // free the buffer behind the LuminanceSource
//    if (imageBytes) {
//        free(imageBytes);
//    }
    // Dynamsoft Barcode Reader SDK
    @autoreleasepool {
        
        void *imageData = NULL;
        uint8_t *copyToAddress;
        
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        
        OSType pixelFormat = CVPixelBufferGetPixelFormatType(imageBuffer);
        
        if (!(pixelFormat == '420v' || pixelFormat == '420f'))
        {
            return;
        }
        
        CVPixelBufferLockBaseAddress(imageBuffer, 0);
        int numPlanes = (int)CVPixelBufferGetPlaneCount(imageBuffer);
        int bufferSize = (int)CVPixelBufferGetDataSize(imageBuffer);
        int imgWidth = (int)CVPixelBufferGetWidthOfPlane(imageBuffer, 0);
        int imgHeight = (int)CVPixelBufferGetHeightOfPlane(imageBuffer, 0);
        
        if(numPlanes < 1)
        {
            return;
        }
        
        uint8_t *baseAddress = (uint8_t *) CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
        size_t bytesToCopy = CVPixelBufferGetHeightOfPlane(imageBuffer, 0) * CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0);
        imageData = malloc(bytesToCopy);
        copyToAddress = (uint8_t *) imageData;
        memcpy(copyToAddress, baseAddress, bytesToCopy);
        
        CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
        
        NSData *buffer = [NSData dataWithBytesNoCopy:imageData length:bufferSize freeWhenDone:YES];
        
        // read frame using Dynamsoft Barcode Reader in async manner
        ReadResult *result = [self.barcodeReader readSingle:buffer width:imgWidth height:imgHeight barcodeFormat: self.barcodeFormat];
        
        if (result.barcodes != nil) {
            Barcode *barcode = (Barcode *)result.barcodes[0];
            [self barcodeScanSucceeded:barcode.displayValue format:barcode.formatString];
        }
        
    }
    
    
}

//--------------------------------------------------------------------------
// for debugging
//--------------------------------------------------------------------------
- (UIImage*)getImageFromSample:(CMSampleBufferRef)sampleBuffer {
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer, 0);

    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width       = CVPixelBufferGetWidth(imageBuffer);
    size_t height      = CVPixelBufferGetHeight(imageBuffer);

    uint8_t* baseAddress    = (uint8_t*) CVPixelBufferGetBaseAddress(imageBuffer);
    int      length         = (int)(height * bytesPerRow);
    uint8_t* newBaseAddress = (uint8_t*) malloc(length);
    memcpy(newBaseAddress, baseAddress, length);
    baseAddress = newBaseAddress;

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(
                                                 baseAddress,
                                                 width, height, 8, bytesPerRow,
                                                 colorSpace,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst
                                                 );

    CGImageRef cgImage = CGBitmapContextCreateImage(context);
    UIImage*   image   = [[UIImage alloc] initWithCGImage:cgImage];

    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    CGImageRelease(cgImage);

    free(baseAddress);

    return image;
}

//--------------------------------------------------------------------------
// for debugging
//--------------------------------------------------------------------------
- (void)dumpImage:(UIImage*)image {
    NSLog(@"writing image to library: %dx%d", (int)image.size.width, (int)image.size.height);
    ALAssetsLibrary* assetsLibrary = [[ALAssetsLibrary alloc] init];
    [assetsLibrary
     writeImageToSavedPhotosAlbum:image.CGImage
     orientation:ALAssetOrientationUp
     completionBlock:^(NSURL* assetURL, NSError* error){
         if (error) NSLog(@"   error writing image to library");
         else       NSLog(@"   wrote image to library %@", assetURL);
     }
     ];
}

@end

//------------------------------------------------------------------------------
// qr encoder processor
//------------------------------------------------------------------------------
@implementation CDVqrProcessor
@synthesize plugin               = _plugin;
@synthesize callback             = _callback;
@synthesize stringToEncode       = _stringToEncode;
@synthesize size                 = _size;

- (id)initWithPlugin:(CDVBarcodeScanner*)plugin callback:(NSString*)callback stringToEncode:(NSString*)stringToEncode{
    self = [super init];
    if (!self) return self;

    self.plugin          = plugin;
    self.callback        = callback;
    self.stringToEncode  = stringToEncode;
    self.size            = 300;

    return self;
}

//--------------------------------------------------------------------------
- (void)dealloc {
    self.plugin = nil;
    self.callback = nil;
    self.stringToEncode = nil;

    [super dealloc];
}
//--------------------------------------------------------------------------
- (void)generateImage{
    /* setup qr filter */
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    [filter setDefaults];

    /* set filter's input message
     * the encoding string has to be convert to a UTF-8 encoded NSData object */
    [filter setValue:[self.stringToEncode dataUsingEncoding:NSUTF8StringEncoding]
              forKey:@"inputMessage"];

    /* on ios >= 7.0  set low image error correction level */
    if (floor(NSFoundationVersionNumber) >= NSFoundationVersionNumber_iOS_7_0)
        [filter setValue:@"L" forKey:@"inputCorrectionLevel"];

    /* prepare cgImage */
    CIImage *outputImage = [filter outputImage];
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef cgImage = [context createCGImage:outputImage
                                       fromRect:[outputImage extent]];

    /* returned qr code image */
    UIImage *qrImage = [UIImage imageWithCGImage:cgImage
                                           scale:1.
                                     orientation:UIImageOrientationUp];
    /* resize generated image */
    CGFloat width = _size;
    CGFloat height = _size;

    UIGraphicsBeginImageContext(CGSizeMake(width, height));

    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetInterpolationQuality(ctx, kCGInterpolationNone);
    [qrImage drawInRect:CGRectMake(0, 0, width, height)];
    qrImage = UIGraphicsGetImageFromCurrentImageContext();

    /* clean up */
    UIGraphicsEndImageContext();
    CGImageRelease(cgImage);

    /* save image to file */
    NSString* filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"tmpqrcode.jpeg"];
    [UIImageJPEGRepresentation(qrImage, 1.0) writeToFile:filePath atomically:YES];

    /* return file path back to cordova */
    [self.plugin returnImage:filePath format:@"QR_CODE" callback: self.callback];
}
@end

//------------------------------------------------------------------------------
// view controller for the ui
//------------------------------------------------------------------------------
@implementation CDVbcsViewController
@synthesize processor      = _processor;
@synthesize shutterPressed = _shutterPressed;
@synthesize alternateXib   = _alternateXib;
@synthesize overlayView    = _overlayView;

//--------------------------------------------------------------------------
- (id)initWithProcessor:(CDVbcsProcessor*)processor alternateOverlay:(NSString *)alternateXib {
    self = [super init];
    if (!self) return self;

    self.processor = processor;
    self.shutterPressed = NO;
    self.alternateXib = alternateXib;
    self.overlayView = nil;
    return self;
}

//--------------------------------------------------------------------------
- (void)dealloc {
    self.view = nil;
    self.processor = nil;
    self.shutterPressed = NO;
    self.alternateXib = nil;
    self.overlayView = nil;
    [super dealloc];
}

//--------------------------------------------------------------------------
- (void)loadView {
    self.view = [[UIView alloc] initWithFrame: self.processor.parentViewController.view.frame];

    // setup capture preview layer
    AVCaptureVideoPreviewLayer* previewLayer = self.processor.previewLayer;
    previewLayer.frame = self.view.bounds;
    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;

    if ([previewLayer.connection isVideoOrientationSupported]) {
        [previewLayer.connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    }

    [self.view.layer insertSublayer:previewLayer below:[[self.view.layer sublayers] objectAtIndex:0]];

    [self.view addSubview:[self buildOverlayView]];
}

//--------------------------------------------------------------------------
- (void)viewWillAppear:(BOOL)animated {

    // set video orientation to what the camera sees
    self.processor.previewLayer.connection.videoOrientation = [[UIApplication sharedApplication] statusBarOrientation];

    // this fixes the bug when the statusbar is landscape, and the preview layer
    // starts up in portrait (not filling the whole view)
    self.processor.previewLayer.frame = self.view.bounds;
}

//--------------------------------------------------------------------------
- (void)viewDidAppear:(BOOL)animated {
    [self startCapturing];

    [super viewDidAppear:animated];
}

//--------------------------------------------------------------------------
- (void)startCapturing {
    self.processor.capturing = YES;
}

//--------------------------------------------------------------------------
- (void)shutterButtonPressed {
    self.shutterPressed = YES;
}

//--------------------------------------------------------------------------
- (IBAction)cancelButtonPressed:(id)sender {
    [self.processor performSelector:@selector(barcodeScanCancelled) withObject:nil afterDelay:0];
}

- (void)flipCameraButtonPressed:(id)sender
{
    [self.processor performSelector:@selector(flipCamera) withObject:nil afterDelay:0];
}

//--------------------------------------------------------------------------
- (UIView *)buildOverlayViewFromXib
{
    [[NSBundle mainBundle] loadNibNamed:self.alternateXib owner:self options:NULL];

    if ( self.overlayView == nil )
    {
        NSLog(@"%@", @"An error occurred loading the overlay xib.  It appears that the overlayView outlet is not set.");
        return nil;
    }

    return self.overlayView;
}

//--------------------------------------------------------------------------
- (UIView*)buildOverlayView {

    if ( nil != self.alternateXib )
    {
        return [self buildOverlayViewFromXib];
    }
    CGRect bounds = self.view.bounds;
    bounds = CGRectMake(0, 0, bounds.size.width, bounds.size.height);

    UIView* overlayView = [[UIView alloc] initWithFrame:bounds];
    overlayView.autoresizesSubviews = YES;
    overlayView.autoresizingMask    = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    overlayView.opaque              = NO;

    UIToolbar* toolbar = [[UIToolbar alloc] init];
    toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;

    id cancelButton = [[UIBarButtonItem alloc]
                       initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                       target:(id)self
                       action:@selector(cancelButtonPressed:)
                       ];


    id flexSpace = [[UIBarButtonItem alloc]
                    initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                    target:nil
                    action:nil
                    ];

    id flipCamera = [[UIBarButtonItem alloc]
                       initWithBarButtonSystemItem:UIBarButtonSystemItemCamera
                       target:(id)self
                       action:@selector(flipCameraButtonPressed:)
                       ];

#if USE_SHUTTER
    id shutterButton = [[UIBarButtonItem alloc]
                        initWithBarButtonSystemItem:UIBarButtonSystemItemCamera
                        target:(id)self
                        action:@selector(shutterButtonPressed)
                        ];

    if (_processor.isShowFlipCameraButton) {
      toolbar.items = [NSArray arrayWithObjects:flexSpace,cancelButton,flexSpace, flipCamera ,shutterButton,nil];
    } else {
      toolbar.items = [NSArray arrayWithObjects:flexSpace,cancelButton,flexSpace ,shutterButton,nil];
    }
#else
    if (_processor.isShowFlipCameraButton) {
      toolbar.items = [NSArray arrayWithObjects:flexSpace,cancelButton,flexSpace, flipCamera,nil];
    } else {
      toolbar.items = [NSArray arrayWithObjects:flexSpace,cancelButton,flexSpace,nil];
    }
#endif
    bounds = overlayView.bounds;

    [toolbar sizeToFit];
    CGFloat toolbarHeight  = [toolbar frame].size.height;
    CGFloat rootViewHeight = CGRectGetHeight(bounds);
    CGFloat rootViewWidth  = CGRectGetWidth(bounds);
    CGRect  rectArea       = CGRectMake(0, rootViewHeight - toolbarHeight, rootViewWidth, toolbarHeight);
    [toolbar setFrame:rectArea];

    [overlayView addSubview: toolbar];

    UIImage* reticleImage = [self buildReticleImage];
    UIView* reticleView = [[UIImageView alloc] initWithImage: reticleImage];
    CGFloat minAxis = MIN(rootViewHeight, rootViewWidth);

    rectArea = CGRectMake(
                          0.5 * (rootViewWidth  - minAxis),
                          0.5 * (rootViewHeight - minAxis),
                          minAxis,
                          minAxis
                          );

    [reticleView setFrame:rectArea];

    reticleView.opaque           = NO;
    reticleView.contentMode      = UIViewContentModeScaleAspectFit;
    reticleView.autoresizingMask = 0
    | UIViewAutoresizingFlexibleLeftMargin
    | UIViewAutoresizingFlexibleRightMargin
    | UIViewAutoresizingFlexibleTopMargin
    | UIViewAutoresizingFlexibleBottomMargin
    ;

    [overlayView addSubview: reticleView];

    return overlayView;
}

//--------------------------------------------------------------------------

#define RETICLE_SIZE    500.0f
#define RETICLE_WIDTH    10.0f
#define RETICLE_OFFSET   60.0f
#define RETICLE_ALPHA     0.4f

//-------------------------------------------------------------------------
// builds the green box and red line
//-------------------------------------------------------------------------
- (UIImage*)buildReticleImage {
    UIImage* result;
    UIGraphicsBeginImageContext(CGSizeMake(RETICLE_SIZE, RETICLE_SIZE));
    CGContextRef context = UIGraphicsGetCurrentContext();

    if (self.processor.is1D) {
        UIColor* color = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:RETICLE_ALPHA];
        CGContextSetStrokeColorWithColor(context, color.CGColor);
        CGContextSetLineWidth(context, RETICLE_WIDTH);
        CGContextBeginPath(context);
        CGFloat lineOffset = RETICLE_OFFSET+(0.5*RETICLE_WIDTH);
        CGContextMoveToPoint(context, lineOffset, RETICLE_SIZE/2);
        CGContextAddLineToPoint(context, RETICLE_SIZE-lineOffset, 0.5*RETICLE_SIZE);
        CGContextStrokePath(context);
    }

    if (self.processor.is2D) {
        UIColor* color = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:RETICLE_ALPHA];
        CGContextSetStrokeColorWithColor(context, color.CGColor);
        CGContextSetLineWidth(context, RETICLE_WIDTH);
        CGContextStrokeRect(context,
                            CGRectMake(
                                       RETICLE_OFFSET,
                                       RETICLE_OFFSET,
                                       RETICLE_SIZE-2*RETICLE_OFFSET,
                                       RETICLE_SIZE-2*RETICLE_OFFSET
                                       )
                            );
    }

    result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return result;
}

#pragma mark CDVBarcodeScannerOrientationDelegate

- (BOOL)shouldAutorotate
{
    return YES;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return [[UIApplication sharedApplication] statusBarOrientation];
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ((self.orientationDelegate != nil) && [self.orientationDelegate respondsToSelector:@selector(shouldAutorotateToInterfaceOrientation:)]) {
        return [self.orientationDelegate shouldAutorotateToInterfaceOrientation:interfaceOrientation];
    }

    return YES;
}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration
{
    [UIView setAnimationsEnabled:NO];
    AVCaptureVideoPreviewLayer* previewLayer = self.processor.previewLayer;
    previewLayer.frame = self.view.bounds;

    if (orientation == UIInterfaceOrientationLandscapeLeft) {
        [previewLayer setOrientation:AVCaptureVideoOrientationLandscapeLeft];
    } else if (orientation == UIInterfaceOrientationLandscapeRight) {
        [previewLayer setOrientation:AVCaptureVideoOrientationLandscapeRight];
    } else if (orientation == UIInterfaceOrientationPortrait) {
        [previewLayer setOrientation:AVCaptureVideoOrientationPortrait];
    } else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
        [previewLayer setOrientation:AVCaptureVideoOrientationPortraitUpsideDown];
    }

    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [UIView setAnimationsEnabled:YES];
}

@end
