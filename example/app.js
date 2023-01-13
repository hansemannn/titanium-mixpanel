import Mixpanel from 'ti.mixpanel';

Mixpanel.initialize({ apiKey: 'YOUR_MIXPANEL_API_KEY' });

Mixpanel.loggingEnabled = true;
Mixpanel.userID = 'my_user_id';

Mixpanel.logEvent('event_name', { param1: 'test', param2: true });
