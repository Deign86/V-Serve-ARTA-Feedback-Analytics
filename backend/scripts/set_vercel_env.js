// Node script to set multiple Vercel env vars via REST API
// Usage: VERCEL_TOKEN env var must be set
// node set_vercel_env.js <projectId> <publicKey> <privateKey> <subject> <adminEmail>

const fetch = require('node-fetch');

async function addEnv(projectId, token, key, value) {
  const url = `https://api.vercel.com/v9/projects/${projectId}/env`;
  const body = { key, value, target: ['preview','production','development'], type: 'encrypted' };
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Authorization': 'Bearer ' + token, 'Content-Type': 'application/json' },
    body: JSON.stringify(body)
  });
  const data = await res.json().catch(() => null);
  return { status: res.status, data };
}

async function main() {
  const args = process.argv.slice(2);
  if (args.length < 5) {
    console.error('Usage: node set_vercel_env.js <projectId> <publicKey> <privateKey> <subject> <adminEmail>');
    process.exit(1);
  }
  const [projectId, publicKey, privateKey, subject, adminEmail] = args;
  const token = process.env.VERCEL_TOKEN;
  if (!token) {
    console.error('VERCEL_TOKEN env var required');
    process.exit(2);
  }

  console.log('Adding VAPID_PUBLIC_KEY...');
  console.log(await addEnv(projectId, token, 'VAPID_PUBLIC_KEY', publicKey));
  console.log('Adding VAPID_PRIVATE_KEY...');
  console.log(await addEnv(projectId, token, 'VAPID_PRIVATE_KEY', privateKey));
  console.log('Adding WEB_PUSH_SUBJECT...');
  console.log(await addEnv(projectId, token, 'WEB_PUSH_SUBJECT', subject));
  console.log('Adding ADMIN_EMAIL...');
  console.log(await addEnv(projectId, token, 'ADMIN_EMAIL', adminEmail));

  console.log('Done. Trigger a redeploy in Vercel to pick up the new vars.');
}

main().catch(e => { console.error(e); process.exit(3); });
