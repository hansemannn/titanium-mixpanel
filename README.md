# Titanium Mixpanel

Use the native Mixpanel Analytics SDK for iOS & Android in Titanium!

## Requirements

- [x] An account on Mixpanel

## APIs

### Methods

- `initialize({ apiKey, trackAutomaticEvents })`: Initialize the SDK
  - `apiKey`: Your Mixpanel project token
  - `trackAutomaticEvents`: (optional) Whether to track automatic events (default: true)

- `logEvent(eventName, additionalParams)`: Log an event
  - `eventName`: Name of the event to track
  - `additionalParams`: (optional) Additional properties to track with the event

- `alias([alias, distinctId])`: Create an alias for a user
  - `alias`: The alias to create
  - `distinctId`: The distinct ID to alias to

- `identify(distinctId)`: Set the distinct ID for the current user
  - `distinctId`: The distinct ID to identify the user with

- `getDistinctID()`: Get the current distinct ID

- `registerSuperProperties(properties)`: Register properties that will be sent with every event
  - `properties`: Object containing the super properties

- `reset()`: Reset the current user's data

- `flush()`: Force sending of queued events to Mixpanel

- `optOutTracking()`: Opt out of tracking

- `optInTracking()`: Opt back into tracking

### Properties

- `loggingEnabled`: Whether or not logging should be enabled

- `userID`: Set the user ID (alias for identify)

## Example

```js
import Mixpanel from 'ti.mixpanel';

// Initialize Mixpanel
Mixpanel.initialize({
    apiKey: 'YOUR_MIXPANEL_TOKEN',
    trackAutomaticEvents: true
});

// Enable logging
Mixpanel.loggingEnabled = true;

// Set user ID
Mixpanel.userID = 'user123';

// Create alias for user
Mixpanel.alias(['alias123', 'user123']);

// Identify user
Mixpanel.identify('user123');

// Get current distinct ID
const distinctId = Mixpanel.getDistinctID();

// Register super properties
Mixpanel.registerSuperProperties({
    app_version: '1.0.0',
    platform: Ti.Platform.osname
});

// Log an event
Mixpanel.logEvent('button_clicked', { 
    button_name: 'main_button',
    timestamp: new Date().toISOString()
});

// Force send events
Mixpanel.flush();

// Reset user data
Mixpanel.reset();

// Opt out of tracking
Mixpanel.optOutTracking();

// Opt back into tracking
Mixpanel.optInTracking();
```

## License

MIT

## Author

Hans Knöchel
