/**
 * titanium-mixpanel
 * Compatible with Mixpanel iOS SDK 5.0.1
 */

#import "TiMixpanelModule.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiUtils.h"
#import <Mixpanel/Mixpanel.h>

static Mixpanel *mx = nil;

@implementation TiMixpanelModule
#pragma mark Internal
- (id)moduleGUID   { return @"cca1c5c0-b2bd-4cf3-b4b4-7b8cb8d02647"; }
- (NSString *)moduleId { return @"ti.mixpanel"; }

#pragma mark Public APIs
- (void)initialize:(id)params
{
  ENSURE_SINGLE_ARG(params, NSDictionary);

  NSString *token = [TiUtils stringValue:@"token" properties:params];
  if (!token || !token.length) {
    NSLog(@"[ti.mixpanel] Initialize requires a non-empty ‘token’");
    return;
  }

  BOOL trackAuto = [TiUtils boolValue:@"trackAutomaticEvents"
                           properties:params
                                  def:YES];

  /* ---- correct 3-param initializer for SDK 5.0.1 ---- */
  mx = [Mixpanel sharedInstanceWithToken:token
                     trackAutomaticEvents:trackAuto
                            trackCrashes:YES];
}

- (void)logEvent:(id)args
{
  ENSURE_TYPE(args, NSArray);

  NSString     *event = ([args count] > 0 && [args[0] isKindOfClass:[NSString class]])
                        ? args[0] : nil;
  NSDictionary *props = ([args count] > 1 && [args[1] isKindOfClass:[NSDictionary class]])
                        ? args[1] : @{};

  if (event) {
    [mx track:event properties:props];
  } else {
    NSLog(@"[ti.mixpanel] logEvent called without event name");
  }
}

- (void)setLoggingEnabled:(id)flag
{
  ENSURE_SINGLE_ARG(flag, NSNumber);
  mx.enableLogging = [flag boolValue];          // property exists in 5.x
}

#pragma mark Identity helpers
- (void)setUserID:(id)userID { [self identify:userID]; }   // legacy shim

- (void)identify:(id)distinctId
{
  ENSURE_SINGLE_ARG(distinctId, NSString);
  [mx identify:distinctId];
}

- (void)alias:(id)args
{
  ENSURE_ARG_COUNT(args, 2);
  NSString *alias      = args[0];
  NSString *distinctId = args[1];

  // Mixpanel SDK 5.x API
  [mx createAlias:alias forDistinctID:distinctId];
}

- (id)getDistinctID:(id)unused
{
  return mx.distinctId ?: @"";
}

#pragma mark Super-props & housekeeping
- (void)registerSuperProperties:(id)props
{
  ENSURE_SINGLE_ARG(props, NSDictionary);
  [mx registerSuperProperties:props];
}

- (void)reset:(id)unused  { [mx reset]; }
- (void)flush:(id)unused  { [mx flush]; }

#pragma mark Privacy
- (void)optOutTracking:(id)unused { [mx optOutTracking]; }
- (void)optInTracking:(id)unused  { [mx optInTracking]; }
@end