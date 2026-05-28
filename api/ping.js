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

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }
  
  try {
    const { dailyToken, version, platform } = req.body;
    if (!dailyToken) {
      return res.status(400).json({ error: 'Missing dailyToken' });
    }

    const today = new Date().toISOString().split('T')[0]; // e.g. "2026-05-28"
    const setKey = `dau:${today}`;
    
    // 1. Add token to the set of daily users (deduplicates automatically)
    await kv.sadd(setKey, dailyToken);
    
    // 2. Set 30 days expiration on the key to save storage automatically
    await kv.expire(setKey, 30 * 24 * 60 * 60);
    
    // 3. Log metadata for version and platform distributions
    const finalVer = version || 'unknown';
    const finalPlatform = platform || 'unknown';
    const metadataKey = `meta:${today}:${finalVer}:${finalPlatform}`;
    await kv.incr(metadataKey);
    await kv.expire(metadataKey, 30 * 24 * 60 * 60);

    return res.status(200).json({ success: true });
  } catch (error) {
    console.error('Telemetry Ping Error:', error);
    return res.status(500).json({ error: 'Internal Server Error', details: error.message });
  }
}
