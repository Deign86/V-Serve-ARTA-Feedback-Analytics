// Example: sending messages to multiple FCM tokens using Firebase Admin SDK
// Place this snippet in a server route or a runnable script after initializing admin

async function sendBatch(tokens, title, body, data) {
  if (!admin || !admin.messaging) {
    console.error('Firebase Admin not configured');
    return;
  }

  const message = {
    notification: { title: title || 'V-Serve Alert', body: body || '' },
    android: { priority: 'high' },
    webpush: { headers: { Urgency: 'high' } },
  };

  // Use sendMulticast for up to 500 tokens per request
  const chunkSize = 500;
  const results = [];
  for (let i = 0; i < tokens.length; i += chunkSize) {
    const batch = tokens.slice(i, i + chunkSize);
    const response = await admin.messaging().sendMulticast({ tokens: batch, ...message });
    results.push({ successCount: response.successCount, failureCount: response.failureCount });
  }

  return results;
}

module.exports = { sendBatch };
