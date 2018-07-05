//
//  QBViewController.h
//  MPC
//
//  Created by Software Engineer on 4/18/18.
//

#import <UIKit/UIKit.h>

@class CDVBarcodeScanner;
@class QBRTCSession;

@interface QBViewController : UIViewController

@property (strong, nonatomic) QBRTCSession *session;
@property (strong, nonatomic) NSString *type;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *answer;
@property (strong, nonatomic) NSString *reCall;
@property (strong, nonatomic) CDVBarcodeScanner *parent;
@property (strong, nonatomic) NSTimer *TimeOfActiveUser;
@property () int tt;
@property () BOOL isMuteAudio;

- (void)initVideo;
- (void)updateVideo;
- (void)initView;

@end
