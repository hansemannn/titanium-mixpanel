/**
 * titanium-mixpanel
 *
 * Created by Hans Knöchel
 * Copyright (c) 2023 Hans Knöchel
 */

#import "TiModule.h"

@interface TiMixpanelModule : TiModule {

}

#pragma mark Public APIs

- (void)initialize:(id)params;
- (void)logEvent:(id)args;
- (void)setLoggingEnabled:(id)loggingEnabled;
- (void)setUserID:(id)userID;
- (void)alias:(id)args;                     // [alias, distinctId]
- (void)identify:(id)distinctId;            // String
- (id)getDistinctID:(id)unused;             // -> String
- (void)registerSuperProperties:(id)props;  // NSDictionary
- (void)reset:(id)unused;
- (void)flush:(id)unused;
- (void)optOutTracking:(id)unused;
- (void)optInTracking:(id)unused;

@end
