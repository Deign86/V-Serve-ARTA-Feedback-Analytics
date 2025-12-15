// firebase-messaging-sw.js
// Replace the firebaseConfig with your project's config if using compat libraries.
importScripts('https://www.gstatic.com/firebasejs/9.22.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.22.0/firebase-messaging-compat.js');

// TODO: Replace with your Firebase project config. For FCM web you can also omit
// initialization here and rely on the main page to initialize. Many setups keep
// the messaging initialization in the SW for background notifications.

const firebaseConfig = {
  apiKey: "YOUR_API_KEY",
  authDomain: "YOUR_AUTH_DOMAIN",
  projectId: "YOUR_PROJECT_ID",
  storageBucket: "YOUR_STORAGE_BUCKET",
  messagingSenderId: "YOUR_SENDER_ID",
  appId: "YOUR_APP_ID",
  measurementId: "YOUR_MEASUREMENT_ID"
};

try {
  firebase.initializeApp(firebaseConfig);
  const messaging = firebase.messaging();

  messaging.onBackgroundMessage(function(payload) {
    console.log('[firebase-messaging-sw.js] Received background message ', payload);
    const notificationTitle = payload.notification?.title || 'Background Message Title';
    const notificationOptions = {
      body: payload.notification?.body || 'Background Message body.',
      icon: payload.notification?.icon || '/icons/Icon-192.png'
    };

    return self.registration.showNotification(notificationTitle, notificationOptions);
  });
} catch (e) {
  console.error('FCM SW init error', e);
}
