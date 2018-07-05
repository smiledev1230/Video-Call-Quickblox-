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
#import <Cordova/CDVPlugin.h>
@class QBRTCSession;

@interface CDVBarcodeScanner : CDVPlugin {}

@property (strong, nonatomic) QBRTCSession *session;
@property (strong, nonatomic) UINavigationController *nav;

- (NSString*)isScanNotPossible;
- (void)scan:(CDVInvokedUrlCommand*)command;
- (void)encode:(CDVInvokedUrlCommand*)command;
- (void)returnImage:(NSString*)filePath format:(NSString*)format callback:(NSString*)callback;
- (void)returnSuccess:(NSString*)scannedText format:(NSString*)format cancelled:(BOOL)cancelled flipped:(BOOL)flipped callback:(NSString*)callback;
- (void)returnError:(NSString*)message callback:(NSString*)callback;

- (void)returnLoginQB:(NSString*)userId callback:(NSString*)callback;
@end

#endif /* CDVBarcodeScanner_h */
