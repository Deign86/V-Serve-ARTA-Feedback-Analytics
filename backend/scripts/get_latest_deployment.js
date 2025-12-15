// Get latest deployment for a projectId and print URL
// Usage: set VERCEL_TOKEN then node get_latest_deployment.js <projectId>

const fetch = require('node-fetch');
(async function(){
  const args = process.argv.slice(2);
  if (args.length < 1) { console.error('Usage: node get_latest_deployment.js <projectId>'); process.exit(1); }
  const pid = args[0];
  const token = process.env.VERCEL_TOKEN;
  if (!token) { console.error('VERCEL_TOKEN not set'); process.exit(2); }
  const res = await (await fetch(`https://api.vercel.com/v6/deployments?projectId=${pid}`, { headers: { Authorization: 'Bearer ' + token } })).json();
  const d = (res.deployments && res.deployments.length) ? res.deployments[0] : null;
  if (!d) { console.error('No deployments found', res); process.exit(3); }
  // deployment URL is d.url or d.aliases[0]
  console.log(JSON.stringify({ url: d.url, aliases: d.aliases || [] }));
})();
