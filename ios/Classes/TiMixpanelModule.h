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

@end
