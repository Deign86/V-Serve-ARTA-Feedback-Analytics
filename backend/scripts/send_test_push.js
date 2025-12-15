/* Simple script to trigger a test push via the backend /push/send endpoint.

Usage:
  node send_test_push.js https://your-backend.example.com "Title" "Body"

If no URL is provided, defaults to http://localhost:5000
*/

const fetch = require('node-fetch');

async function main() {
  const args = process.argv.slice(2);
  const base = args[0] || 'http://localhost:5000';
  const title = args[1] || 'Test Push';
  const body = args[2] || 'This is a test from send_test_push.js';

  const resp = await fetch(`${base.replace(/\/$/, '')}/push/send`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ title, body }),
  });

  const data = await resp.json().catch(() => null);
  console.log('Status:', resp.status, data);
}

main().catch(err => {
  console.error('Error sending test push:', err);
  process.exit(1);
});
