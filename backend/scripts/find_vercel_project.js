// Usage: set VERCEL_TOKEN env var and run `node find_vercel_project.js`
(async function(){
  const token = process.env.VERCEL_TOKEN;
  if (!token) {
    console.error('VERCEL_TOKEN not set');
    process.exit(1);
  }

  try {
    const res = await fetch('https://api.vercel.com/v9/projects', {
      headers: { Authorization: 'Bearer ' + token }
    });
    const data = await res.json();
    const projects = data.projects || [];
    for (const p of projects) {
      console.log(JSON.stringify({ id: p.id, name: p.name, slug: p.slug, owner: (p.owner && p.owner.name) ? p.owner.name : null }));
    }
  } catch (e) {
    console.error('Error fetching projects:', e);
    process.exit(2);
  }
})();
