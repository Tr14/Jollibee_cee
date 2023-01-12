#import "AppDelegate.h"

#import <React/RCTBridge.h>
#import <React/RCTBundleURLProvider.h>
#import <React/RCTRootView.h>

#import <React/RCTAppSetupUtils.h>

#if RCT_NEW_ARCH_ENABLED
#import <React/CoreModulesPlugins.h>
#import <React/RCTCxxBridgeDelegate.h>
#import <React/RCTFabricSurfaceHostingProxyRootView.h>
#import <React/RCTSurfacePresenter.h>
#import <React/RCTSurfacePresenterBridgeAdapter.h>
#import <ReactCommon/RCTTurboModuleManager.h>

#import <react/config/ReactNativeConfig.h>

#import "SmartechPushReactnative.h"
#import "SmartechPushReactEventEmitter.h"

#import "NotificationService.h"

@interface AppDelegate () <RCTCxxBridgeDelegate, RCTTurboModuleManagerDelegate, SmartechDelegate, UNUserNotificationCenterDelegate> {
  RCTTurboModuleManager *_turboModuleManager;
  RCTSurfacePresenterBridgeAdapter *_bridgeAdapter;
  std::shared_ptr<const facebook::react::ReactNativeConfig> _reactNativeConfig;
  facebook::react::ContextContainer::Shared _contextContainer;
  NSMutableDictionary *smtDeeplinkData;
}
@end
#endif

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  RCTAppSetupPrepareApp(application);

  RCTBridge *bridge = [[RCTBridge alloc] initWithDelegate:self launchOptions:launchOptions];
  
  [[UIApplication sharedApplication] registerForRemoteNotifications];
  
  [FIRApp configure];
  
  [UNUserNotificationCenter currentNotificationCenter].delegate = (id)self;
  UNAuthorizationOptions authOptions = UNAuthorizationOptionAlert |
      UNAuthorizationOptionSound | UNAuthorizationOptionBadge;
  [[UNUserNotificationCenter currentNotificationCenter]
      requestAuthorizationWithOptions:authOptions
      completionHandler:^(BOOL granted, NSError * _Nullable error) {
        // ...
      }];

  [application registerForRemoteNotifications];
  
  //FCM
  [FIRMessaging messaging].delegate = (id)self;
  
  [[FIRMessaging messaging] tokenWithCompletion:^(NSString *token, NSError *error) {
    if (error != nil) {
      NSLog(@"Error getting FCM registration token: %@", error);
    } else {
      NSLog(@"FCM registration token: %@", token);
    }
  }];
  
  NSLog(@"[SMT-APP] didFinishLaunchingWithOptions = %@", launchOptions);
  
  // Smartech Native SDK
  [[Smartech sharedInstance] initSDKWithDelegate:(id)self withLaunchOptions:launchOptions];
  [[Smartech sharedInstance] setDebugLevel:SMTLogLevelVerbose];
  
  //[[SmartPush sharedInstance] registerForPushNotificationWithDefaultAuthorizationOptions];
  [[Smartech sharedInstance] trackAppInstallUpdateBySmartech];
  [UNUserNotificationCenter currentNotificationCenter].delegate = (id)self;
  
#if RCT_NEW_ARCH_ENABLED
  _contextContainer = std::make_shared<facebook::react::ContextContainer const>();
  _reactNativeConfig = std::make_shared<facebook::react::EmptyReactNativeConfig const>();
  _contextContainer->insert("ReactNativeConfig", _reactNativeConfig);
  _bridgeAdapter = [[RCTSurfacePresenterBridgeAdapter alloc] initWithBridge:bridge contextContainer:_contextContainer];
  bridge.surfacePresenter = _bridgeAdapter.surfacePresenter;
#endif

  UIView *rootView = RCTAppSetupDefaultRootView(bridge, @"Jollibee_cee", nil);

  if (@available(iOS 13.0, *)) {
    rootView.backgroundColor = [UIColor systemBackgroundColor];
  } else {
    rootView.backgroundColor = [UIColor whiteColor];
  }

  self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  UIViewController *rootViewController = [UIViewController new];
  rootViewController.view = rootView;
  self.window.rootViewController = rootViewController;
  [self.window makeKeyAndVisible];
  
  return YES;
}

// Register for Push Notification
- (void)messaging:(FIRMessaging *)messaging didReceiveRegistrationToken:(NSString *)deviceToken {
    NSLog(@"FCM registration token: %@", deviceToken);
    // Notify about received token.
    NSDictionary *dataDict = [NSDictionary dictionaryWithObject:deviceToken forKey:@"token"];
    [[NSNotificationCenter defaultCenter] postNotificationName:
     @"FCMToken" object:nil userInfo:dataDict];
    // TODO: If necessary send token to application server.
    // Note: This callback is fired at each app startup and whenever a new token is generated.
}


// With "FirebaseAppDelegateProxyEnabled": NO
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
  NSLog(@"[SMT-APP] didRegisterForRemoteNotificationsWithDeviceToken");
  [[FIRMessaging messaging] setAPNSToken:deviceToken];
  [[SmartPush sharedInstance] didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
  NSLog(@"[SMT-APP] didFailToRegisterForRemoteNotificationsWithError = %@", [error localizedFailureReason]);
  [[SmartPush sharedInstance] didFailToRegisterForRemoteNotificationsWithError:error];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
  NSLog(@"[SMT-APP] didReceiveRemoteNotification Silent Notification");
  if ([[SmartPush sharedInstance] isNotificationFromSmartech:userInfo]) {
    [[SmartPush sharedInstance] didReceiveRemoteNotification:userInfo withCompletionHandler:^(UIBackgroundFetchResult bgFetchResult) {
      completionHandler(bgFetchResult);
    }];
  }
  else {
    completionHandler(UIBackgroundFetchResultNewData);
  }
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
  NSLog(@"[SMT-APP] application Active");
}

#pragma mark - UNUserNotificationCenterDelegate Methods

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
  NSLog(@"[SMT-APP] willPresentNotification");
  [[SmartPush sharedInstance] willPresentForegroundNotification:notification];
  completionHandler(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
  NSLog(@"[SMT-APP] didReceiveNotificationResponse %@",response.notification.request.content);
  [[SmartPush sharedInstance] didReceiveNotificationResponse:response];
  completionHandler();
}

- (NSURL *)sourceURLForBridge:(RCTBridge *)bridge
{
#if DEBUG
  return [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index"];
#else
  return [[NSBundle mainBundle] URLForResource:@"main" withExtension:@"jsbundle"];
#endif
}

#if RCT_NEW_ARCH_ENABLED

#pragma mark - RCTCxxBridgeDelegate

- (std::unique_ptr<facebook::react::JSExecutorFactory>)jsExecutorFactoryForBridge:(RCTBridge *)bridge
{
  _turboModuleManager = [[RCTTurboModuleManager alloc] initWithBridge:bridge
                                                             delegate:self
                                                            jsInvoker:bridge.jsCallInvoker];
  return RCTAppSetupDefaultJsExecutorFactory(bridge, _turboModuleManager);
}

#pragma mark RCTTurboModuleManagerDelegate

- (Class)getModuleClassFromName:(const char *)name
{
  return RCTCoreModulesClassProvider(name);
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:(const std::string &)name
                                                      jsInvoker:(std::shared_ptr<facebook::react::CallInvoker>)jsInvoker
{
  return nullptr;
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:(const std::string &)name
                                                     initParams:
                                                         (const facebook::react::ObjCTurboModule::InitParams &)params
{
  return nullptr;
}

- (id<RCTTurboModule>)getModuleInstanceFromClass:(Class)moduleClass
{
  return RCTAppSetupDefaultModuleFromClass(moduleClass);
}

#endif

@end
