/* Service Worker for handling Web Push messages */
'use strict';

self.addEventListener('push', function(event) {
  let payload = {};
  try {
    if (event.data) payload = event.data.json();
  } catch (e) {
    try { payload = JSON.parse(event.data.text()); } catch (_) { payload = { body: event.data?.text() || '' }; }
  }

  const title = payload.title || 'V-Serve Alert';
  const options = {
    body: payload.body || '',
    data: payload.data || {},
    tag: payload.tag || ('vserve-' + Date.now()),
    requireInteraction: !!payload.requireInteraction,
    icon: payload.icon || '/favicon.png'
  };

  event.waitUntil(self.registration.showNotification(title, options));
});

self.addEventListener('notificationclick', function(event) {
  event.notification.close();
  const urlToOpen = (event.notification.data && event.notification.data.url) || '/';

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function(windowClients) {
      for (let i = 0; i < windowClients.length; i++) {
        const client = windowClients[i];
        if (client.url === urlToOpen && 'focus' in client) return client.focus();
      }
      if (clients.openWindow) return clients.openWindow(urlToOpen);
    })
  );
});
