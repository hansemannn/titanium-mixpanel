# Titanium Mixpanel

Use the native Mixpanel Analytics SDK for iOS & Android in Titanium!

## Requirements

- [x] An account on Mixpanel

## APIs

### Methods

- `initialize({ apiKey })`: Initialize the SDK

- `logEvent(eventName, additionalParams)`: Log an event

### Properties

- `loggingEnabled`: Whether or not logging should be enabled

- `userID`: Set the user ID

## Example

```js
import Mixpanel from 'ti.mixpanel';

const window = Ti.UI.createWindow();
const btn = Ti.UI.createButton({ title: 'Log event' });

btn.addEventListener('click', () => Mixpanel.logEvent('my_screen', { param: 1 }));
window.add(btn);
window.open();
```

## License

MIT

## Author

Hans Knöchel
