import Mixpanel from 'ti.mixpanel';

// Initialize Mixpanel with your project token
Mixpanel.initialize({
    apiKey: 'YOUR_MIXPANEL_TOKEN',
    trackAutomaticEvents: true
});

// Enable logging (optional)
Mixpanel.loggingEnabled = true;

// Set user ID
Mixpanel.userID = 'user123';

// Create alias for user (useful for tracking users across different IDs)
Mixpanel.alias(['alias123', 'user123']);

// Identify user (sets the distinct ID)
Mixpanel.identify('user123');

// Get current distinct ID
const distinctId = Mixpanel.getDistinctID();
console.log('Current distinct ID:', distinctId);

// Register super properties that will be sent with every event
Mixpanel.registerSuperProperties({
    app_version: '1.0.0',
    platform: Ti.Platform.osname
});

// Create UI
const window = Ti.UI.createWindow();
const btn = Ti.UI.createButton({ title: 'Log event' });

btn.addEventListener('click', () => {
    // Log an event with properties
    Mixpanel.logEvent('button_clicked', { 
        button_name: 'main_button',
        timestamp: new Date().toISOString()
    });
});

// Add flush button to force sending events
const flushBtn = Ti.UI.createButton({ 
    title: 'Flush Events',
    top: 50
});

flushBtn.addEventListener('click', () => {
    Mixpanel.flush();
});

// Add reset button to clear user data
const resetBtn = Ti.UI.createButton({ 
    title: 'Reset User',
    top: 100
});

resetBtn.addEventListener('click', () => {
    Mixpanel.reset();
});

// Add opt-out button
const optOutBtn = Ti.UI.createButton({ 
    title: 'Opt Out',
    top: 150
});

optOutBtn.addEventListener('click', () => {
    Mixpanel.optOutTracking();
});

// Add opt-in button
const optInBtn = Ti.UI.createButton({ 
    title: 'Opt In',
    top: 200
});

optInBtn.addEventListener('click', () => {
    Mixpanel.optInTracking();
});

window.add(btn);
window.add(flushBtn);
window.add(resetBtn);
window.add(optOutBtn);
window.add(optInBtn);
window.open();
