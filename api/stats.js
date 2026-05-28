import { kv } from '@vercel/kv';

export default async function handler(req, res) {
  // CORS configuration
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version'
  );

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  // Simple stats authorization key
  if (req.query.key !== process.env.STATS_API_KEY) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  try {
    const today = new Date().toISOString().split('T')[0];
    
    // SCARD instantly returns the size of the unique set (unique users)
    const activeUsers = await kv.scard(`dau:${today}`);
    
    return res.status(200).json({ 
      date: today,
      daily_active_users: activeUsers 
    });
  } catch (error) {
    console.error('Telemetry Stats Error:', error);
    return res.status(500).json({ error: 'Internal Server Error', details: error.message });
  }
}
