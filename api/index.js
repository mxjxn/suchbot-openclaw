import express from 'express';
import cors from 'cors';
import crypto from 'crypto';
import fs from 'fs';
import path from 'path';
import { createCanvas, loadImage } from 'canvas';

const app = express();
const PORT = 3001;
const NOTIFICATIONS_FILE = '/root/.openclaw/workspace/api/notifications.json';
const BLOG_DIR = '/root/.openclaw/workspace/web/blog';

// Neynar webhook config - set these in ~/.openclaw/.env
const NEYNAR_WEBHOOK_SECRET = process.env.NEYNAR_WEBHOOK_SECRET || '';

app.use(cors());

// Raw body parser for webhook signature verification
app.use('/webhooks/farcaster', express.raw({ type: 'application/json' }));
app.use(express.json());

// Ensure notifications file exists
if (!fs.existsSync(NOTIFICATIONS_FILE)) {
  fs.writeFileSync(NOTIFICATIONS_FILE, '[]');
}

// Helper to add notification
function addNotification(type, data) {
  const notifications = JSON.parse(fs.readFileSync(NOTIFICATIONS_FILE, 'utf8'));
  notifications.push({
    id: Date.now(),
    type,
    data,
    timestamp: new Date().toISOString(),
    read: false
  });
  fs.writeFileSync(NOTIFICATIONS_FILE, JSON.stringify(notifications, null, 2));
}

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', agent: 'suchbot', agentId: 2243 });
});

// OpenGraph image generator
app.get('/og', async (req, res) => {
  try {
    const { title, description } = req.query;
    const displayTitle = title || 'Suchbot';
    const displayDesc = description || 'AI agent for MXJXN. Working on art, onchain projects, and whatever else needs doing.';
    
    const width = 1200;
    const height = 630;
    const canvas = createCanvas(width, height);
    const ctx = canvas.getContext('2d');
    
    // Background gradient
    const gradient = ctx.createLinearGradient(0, 0, width, height);
    gradient.addColorStop(0, '#1a1a2e');
    gradient.addColorStop(1, '#16213e');
    ctx.fillStyle = gradient;
    ctx.fillRect(0, 0, width, height);
    
    // Subtle pattern
    ctx.strokeStyle = 'rgba(255, 255, 255, 0.03)';
    ctx.lineWidth = 1;
    for (let i = 0; i < width; i += 40) {
      ctx.beginPath();
      ctx.moveTo(i, 0);
      ctx.lineTo(i, height);
      ctx.stroke();
    }
    for (let i = 0; i < height; i += 40) {
      ctx.beginPath();
      ctx.moveTo(0, i);
      ctx.lineTo(width, i);
      ctx.stroke();
    }
    
    // Accent bar
    ctx.fillStyle = '#e53935';
    ctx.fillRect(0, 0, width, 6);
    
    // Emoji
    ctx.font = '120px sans-serif';
    ctx.textAlign = 'left';
    ctx.textBaseline = 'middle';
    ctx.fillText('👹', 60, height / 2 - 30);
    
    // Title
    ctx.fillStyle = '#ffffff';
    ctx.font = 'bold 64px system-ui, -apple-system, BlinkMacSystemFont, sans-serif';
    ctx.textAlign = 'left';
    
    // Word wrap title
    const maxWidth = width - 250;
    const words = displayTitle.split(' ');
    let line = '';
    let y = height / 2 - 50;
    
    for (let i = 0; i < words.length; i++) {
      const testLine = line + words[i] + ' ';
      const metrics = ctx.measureText(testLine);
      if (metrics.width > maxWidth && i > 0) {
        ctx.fillText(line.trim(), 250, y);
        line = words[i] + ' ';
        y += 75;
      } else {
        line = testLine;
      }
    }
    ctx.fillText(line.trim(), 250, y);
    
    // Description
    if (displayDesc) {
      ctx.fillStyle = '#a0a0b0';
      ctx.font = '28px system-ui, -apple-system, BlinkMacSystemFont, sans-serif';
      
      // Truncate description
      const maxWidthDesc = width - 250;
      let desc = displayDesc;
      while (ctx.measureText(desc + '...').width > maxWidthDesc && desc.length > 0) {
        desc = desc.slice(0, -1);
      }
      ctx.fillText(desc + (desc !== displayDesc ? '...' : ''), 250, y + 60);
    }
    
    // Footer
    ctx.fillStyle = '#e53935';
    ctx.font = 'bold 20px system-ui, -apple-system, BlinkMacSystemFont, sans-serif';
    ctx.fillText('bot.mxjxn.xyz', 60, height - 40);
    
    ctx.fillStyle = '#606070';
    ctx.font = '18px system-ui, -apple-system, BlinkMacSystemFont, sans-serif';
    ctx.textAlign = 'right';
    ctx.fillText('Agent #2243 on Base', width - 60, height - 40);
    
    // Send image
    res.setHeader('Content-Type', 'image/png');
    res.setHeader('Cache-Control', 'public, max-age=3600');
    canvas.createPNGStream().pipe(res);
  } catch (err) {
    console.error('OG image error:', err);
    res.status(500).json({ error: 'Failed to generate OG image' });
  }
});

// Blog - list all posts (deprecated, using Astro Content Collections now)
app.get('/posts', (req, res) => {
  res.json([]);
});

// Blog - get single post (deprecated, using Astro Content Collections now)
app.get('/posts/:slug', (req, res) => {
  try {
    const filename = `${req.params.slug}.md`;
    const filepath = path.join(BLOG_DIR, filename);
    
    if (!fs.existsSync(filepath)) {
      return res.status(404).json({ error: 'Post not found' });
    }
    
    const content = fs.readFileSync(filepath, 'utf8');
    const post = parsePost(content, filename);
    
    if (!post) {
      return res.status(500).json({ error: 'Invalid post format' });
    }
    
    res.json(post);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Contact form - leave a message
app.post('/contact', (req, res) => {
  const { handle, platform, message } = req.body;
  
  if (!handle || typeof handle !== 'string' || !handle.trim()) {
    return res.status(400).json({ error: 'Missing handle' });
  }
  
  if (!platform || !['telegram', 'farcaster'].includes(platform)) {
    return res.status(400).json({ error: 'Platform must be "telegram" or "farcaster"' });
  }
  
  if (!message || typeof message !== 'string' || !message.trim()) {
    return res.status(400).json({ error: 'Missing message' });
  }
  
  if (message.length > 2000) {
    return res.status(400).json({ error: 'Message too long (max 2000 chars)' });
  }
  
  // Log notification for the agent
  addNotification('contact', {
    handle: handle.trim(),
    platform,
    message: message.trim(),
    ip: req.ip || req.socket.remoteAddress,
    userAgent: req.headers['user-agent']
  });
  
  res.json({ 
    success: true,
    message: "Got it! I'll get back to you soon."
  });
});

// Internal endpoint for agent to check/clear notifications
app.get('/notifications', (req, res) => {
  const notifications = JSON.parse(fs.readFileSync(NOTIFICATIONS_FILE, 'utf8'));
  res.json(notifications.filter(n => !n.read));
});

app.post('/notifications/clear', (req, res) => {
  const { ids } = req.body;
  let notifications = JSON.parse(fs.readFileSync(NOTIFICATIONS_FILE, 'utf8'));
  
  if (ids && Array.isArray(ids)) {
    notifications = notifications.map(n => 
      ids.includes(n.id) ? { ...n, read: true } : n
    );
  } else {
    notifications = notifications.map(n => ({ ...n, read: true }));
  }
  
  fs.writeFileSync(NOTIFICATIONS_FILE, JSON.stringify(notifications, null, 2));
  res.json({ cleared: true });
});

// Owner FID for priority notifications
const OWNER_FID = 4905; // @mxjxn on Farcaster
const TELEGRAM_BOT_TOKEN = process.env.TELEGRAM_BOT_TOKEN || '';
const TELEGRAM_OWNER_ID = '1231002024';

// Forward priority Farcaster messages to Telegram
async function forwardToTelegram(message) {
  if (!TELEGRAM_BOT_TOKEN) {
    console.log('No Telegram bot token configured, skipping forward');
    return;
  }
  try {
    const res = await fetch(`https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        chat_id: TELEGRAM_OWNER_ID,
        text: message,
        parse_mode: 'Markdown'
      })
    });
    const data = await res.json();
    console.log('Telegram forward:', data.ok ? 'sent' : data.description);
  } catch (err) {
    console.error('Failed to forward to Telegram:', err.message);
  }
}

// Neynar Farcaster webhook
// Receives: mentions, replies, casts in channels, etc.
app.post('/webhooks/farcaster', async (req, res) => {
  const signature = req.headers['x-neynar-signature'];
  const rawBody = req.body;
  
  // Verify signature if secret is configured
  if (NEYNAR_WEBHOOK_SECRET) {
    const expectedSig = crypto
      .createHmac('sha512', NEYNAR_WEBHOOK_SECRET)
      .update(rawBody)
      .digest('hex');
    
    if (signature !== expectedSig) {
      console.error('Webhook signature mismatch');
      return res.status(401).json({ error: 'Invalid signature' });
    }
  }
  
  let payload;
  try {
    payload = JSON.parse(rawBody.toString());
  } catch (e) {
    return res.status(400).json({ error: 'Invalid JSON' });
  }
  
  console.log('Farcaster webhook received:', payload.type);
  
  // Extract relevant data based on event type
  const eventType = payload.type || 'unknown';
  const data = payload.data || {};
  
  const notificationData = {
    type: eventType,
    hash: data.hash,
    author: data.author?.username,
    authorFid: data.author?.fid,
    text: data.text,
    parentHash: data.parent_hash,
    parentAuthor: data.parent_author?.username,
    channel: data.channel?.id,
    timestamp: data.timestamp,
    raw: data
  };
  
  // Add to notifications for the agent to process
  addNotification('farcaster_' + eventType, notificationData);
  
  // If message is from owner, forward to Telegram for immediate attention
  if (data.author?.fid === OWNER_FID) {
    console.log('Priority message from owner, forwarding to Telegram...');
    await forwardToTelegram(
      `🔔 *Farcaster from @${data.author.username}*\n\n${data.text}\n\n_Reply to this cast:_ \`${data.hash}\``
    );
  }
  
  res.json({ success: true });
});

app.listen(PORT, () => {
  console.log(`Suchbot API listening on port ${PORT}`);
});
