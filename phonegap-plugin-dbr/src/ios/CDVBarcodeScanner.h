//
//  CDVBarcodeScanner.h
//  MPC
//
//  Created by Software Engineer on 4/21/18.
//

#ifndef CDVBarcodeScanner_h
#define CDVBarcodeScanner_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <PushKit/PushKit.h>
#import <Cordova/CDVPlugin.h>
@class QBRTCSession;
@class QBViewController;

@interface CDVBarcodeScanner : CDVPlugin {}

@property (strong, nonatomic) QBRTCSession *session;
@property (strong, nonatomic) UINavigationController *nav;
@property (strong, nonatomic) NSString *notficationReceivedCallbackId11;
@property (strong, nonatomic) NSString *notficationEndReceivedCallbackId11;
@property (strong, nonatomic) NSString *notficationAcceptReceivedCallbackId11;
@property (strong, nonatomic) PKPushRegistry *voipRegistry;
@property (strong, nonatomic) NSDictionary *userInfo;
@property (strong, nonatomic) NSUUID *callUUID;
@property (strong, nonatomic) NSString *reCall;
@property (strong, nonatomic) QBViewController *qbView;

- (NSString*)isScanNotPossible;
- (void)scan:(CDVInvokedUrlCommand*)command;
- (void)encode:(CDVInvokedUrlCommand*)command;
- (void)returnImage:(NSString*)filePath format:(NSString*)format callback:(NSString*)callback;
- (void)returnSuccess:(NSString*)scannedText format:(NSString*)format cancelled:(BOOL)cancelled flipped:(BOOL)flipped callback:(NSString*)callback;
- (void)returnError:(NSString*)message callback:(NSString*)callback;

- (void)returnLoginQB:(NSString*)userId callback:(NSString*)callback;
@end

#endif /* CDVBarcodeScanner_h */
