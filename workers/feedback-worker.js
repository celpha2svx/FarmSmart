// Cloudflare Worker: farmsmart-feedback
// Deploy: wrangler deploy
// Set secrets: echo "GITHUB_TOKEN=ghp_xxx" | wrangler secret put GITHUB_TOKEN

export default {
  async fetch(request) {
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'POST',
          'Access-Control-Allow-Headers': 'Content-Type',
        },
      });
    }

    if (request.method !== 'POST') {
      return new Response('Method not allowed', { status: 405 });
    }

    try {
      const { message, source } = await request.json();
      if (!message || message.trim().length === 0) {
        return new Response(JSON.stringify({ error: 'message is required' }), {
          status: 400,
          headers: { 'Content-Type': 'application/json' },
        });
      }

      const GITHUB_TOKEN = globalThis.GITHUB_TOKEN;
      if (!GITHUB_TOKEN) {
        return new Response(JSON.stringify({ error: 'Server not configured' }), {
          status: 500,
          headers: { 'Content-Type': 'application/json' },
        });
      }

      const response = await fetch(
        'https://api.github.com/repos/celpha2svx/FarmSmart/issues',
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${GITHUB_TOKEN}`,
            'Content-Type': 'application/json',
            'User-Agent': 'farmsmart-feedback-worker',
          },
          body: JSON.stringify({
            title: `Feedback from ${source || 'mobile app'}`,
            body: `**Source:** ${source || 'unknown'}\n\n${message}`,
            labels: ['feedback'],
          }),
        }
      );

      const result = await response.json();
      return new Response(JSON.stringify(result), {
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      });
    } catch (e) {
      return new Response(JSON.stringify({ error: e.message }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      });
    }
  },
};
