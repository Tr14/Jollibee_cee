#import <React/RCTBridgeDelegate.h>
#import <UIKit/UIKit.h>
#import <Smartech/Smartech.h>
#import <SmartPush/SmartPush.h>
#import <FIRMessaging.h>
#import <FIRApp.h>
#import <FIRInstallations.h>
@interface AppDelegate : UIResponder <UIApplicationDelegate, RCTBridgeDelegate>

@property (nonatomic, strong) UIWindow *window;

@end
