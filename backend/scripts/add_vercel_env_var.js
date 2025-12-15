// Adds a single environment variable to a Vercel project
// Usage: set VERCEL_TOKEN then:
// node add_vercel_env_var.js <projectId> <key> <value>

const fetch = require('node-fetch');

async function main() {
  const args = process.argv.slice(2);
  if (args.length < 3) {
    console.error('Usage: node add_vercel_env_var.js <projectId> <key> <value>');
    process.exit(1);
  }
  const [projectId, key, value] = args;
  const token = process.env.VERCEL_TOKEN;
  if (!token) {
    console.error('VERCEL_TOKEN env var required');
    process.exit(2);
  }
  const url = `https://api.vercel.com/v9/projects/${projectId}/env`;
  const body = { key, value, target: ['preview','production','development'], type: 'encrypted' };
  const res = await fetch(url, { method: 'POST', headers: { Authorization: 'Bearer ' + token, 'Content-Type': 'application/json' }, body: JSON.stringify(body) });
  const data = await res.json().catch(() => null);
  console.log(res.status, data);
}

main().catch(e => { console.error(e); process.exit(3); });
