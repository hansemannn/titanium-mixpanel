/**
 * titanium-mixpanel
 *
 * Created by Hans Knöchel
 * Copyright (c) 2023 Hans Knöchel
 */

#import "TiMixpanelModule.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiUtils.h"

#import <Mixpanel/Mixpanel.h>

@implementation TiMixpanelModule

#pragma mark Internal

- (id)moduleGUID
{
  return @"cca1c5c0-b2bd-4cf3-b4b4-7b8cb8d02647";
}

- (NSString *)moduleId
{
  return @"ti.mixpanel";
}

#pragma mark Public APIs

- (void)initialize:(id)params
{
  ENSURE_SINGLE_ARG(params, NSDictionary);
  
  NSString *apiKey = [TiUtils stringValue:@"apiKey" properties:params];
  BOOL trackAutomaticEvents = [TiUtils boolValue:@"trackAutomaticEvents" properties:params def:YES];

  [Mixpanel sharedInstanceWithToken:apiKey trackAutomaticEvents:trackAutomaticEvents];
}

- (void)logEvent:(id)args
{
  NSString *eventName = args[0];
  NSDictionary<NSString *, id> *properties = args[1];

  [[Mixpanel sharedInstance] track:eventName properties:properties];
}

- (void)setLoggingEnabled:(id)loggingEnabled
{
  ENSURE_SINGLE_ARG(loggingEnabled, NSNumber);
  [[Mixpanel sharedInstance] setEnableLogging:[TiUtils boolValue:loggingEnabled]];
}

- (void)setUserID:(id)userID
{
  ENSURE_SINGLE_ARG(userID, NSString);
  [[Mixpanel sharedInstance] identify:userID];
}

@end
