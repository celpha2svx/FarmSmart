const { GITHUB_TOKEN, GITHUB_REPO } = process.env;

export default {
  async fetch(request, env) {
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    };
    if (request.method === 'OPTIONS') return new Response(null, { headers: corsHeaders });
    if (request.method !== 'POST') return new Response(JSON.stringify({ error: 'Method not allowed' }), { status: 405, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });

    try {
      const { phone, category, message, app_version, device_info, feedback_id } = await request.json();
      if (!message) return new Response(JSON.stringify({ error: 'Message is required' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });

      const title = `[${category || 'other'}] ${message.substring(0, 60)}${message.length > 60 ? '...' : ''}`;
      const body = `## Feedback\n\n**Category:** ${category || 'N/A'}\n**App:** ${app_version || 'N/A'}\n**Device:** ${device_info || 'N/A'}\n**Phone:** ${phone ? phone.replace(/(\d{3})\d{4}(\d{4})/, '$1****$2') : 'N/A'}\n**ID:** ${feedback_id || 'N/A'}\n\n---\n\n${message}`;

      const r = await fetch(`https://api.github.com/repos/${env.GITHUB_REPO}/issues`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${env.GITHUB_TOKEN}`, 'Content-Type': 'application/json', 'User-Agent': 'FarmSmart' },
        body: JSON.stringify({ title, body, labels: ['feedback', category || 'other'] }),
      });

      if (!r.ok) {
        const t = await r.text();
        console.error('GitHub error:', r.status, t);
        return new Response(JSON.stringify({ error: 'GitHub API error' }), { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
      }

      const data = await r.json();
      return new Response(JSON.stringify({ status: 'ok', issue_url: data.html_url, issue_number: data.number }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    } catch (e) {
      console.error('Worker error:', e);
      return new Response(JSON.stringify({ error: 'Internal error' }), { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
    }
  },
};
