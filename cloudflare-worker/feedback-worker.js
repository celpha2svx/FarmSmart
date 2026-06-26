/**
 * FarmSmart Feedback → GitHub Issue
 * 
 * Cloudflare Worker that receives feedback from the FarmSmart app
 * and creates a GitHub Issue for tracking.
 *
 * Deploy:
 *   wrangler deploy
 *
 * Environment variables (set in Cloudflare Dashboard):
 *   GITHUB_TOKEN  - GitHub Personal Access Token with "issues:write" scope
 *   GITHUB_REPO   - "celpha2svx/FarmSmart"
 */

export default {
  async fetch(request, env) {
    // CORS headers
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    };

    // Handle OPTIONS (CORS preflight)
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    // Only accept POST
    if (request.method !== 'POST') {
      return new Response(JSON.stringify({ error: 'Method not allowed' }), {
        status: 405,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    try {
      const body = await request.json();
      const { phone, category, message, app_version, device_info, feedback_id } = body;

      if (!message) {
        return new Response(JSON.stringify({ error: 'Message is required' }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      // Build GitHub Issue
      const categoryLabel = category || 'other';
      const title = `[Feedback] ${categoryLabel}: ${message.substring(0, 60)}${message.length > 60 ? '...' : ''}`;
      const issueBody = `
## Feedback Report

**Category:** ${categoryLabel}
**App Version:** ${app_version || 'N/A'}
**Device:** ${device_info || 'N/A'}
**Phone:** ${phone ? phone.replace(/(\d{3})\d{4}(\d{4})/, '$1****$2') : 'N/A'}
**Feedback ID:** ${feedback_id || 'N/A'}

---

### Message
${message}
      `.trim();

      // Create GitHub Issue
      const githubResponse = await fetch(
        `https://api.github.com/repos/${env.GITHUB_REPO}/issues`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${env.GITHUB_TOKEN}`,
            'Content-Type': 'application/json',
            'User-Agent': 'FarmSmart-Feedback-Worker',
          },
          body: JSON.stringify({
            title,
            body: issueBody,
            labels: ['feedback', categoryLabel],
          }),
        }
      );

      if (!githubResponse.ok) {
        const errorText = await githubResponse.text();
        console.error('GitHub API error:', githubResponse.status, errorText);
        return new Response(JSON.stringify({ error: 'Failed to create issue' }), {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      const issueData = await githubResponse.json();

      return new Response(
        JSON.stringify({
          status: 'ok',
          issue_url: issueData.html_url,
          issue_number: issueData.number,
        }),
        {
          status: 200,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    } catch (error) {
      console.error('Worker error:', error);
      return new Response(JSON.stringify({ error: 'Internal error' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }
  },
};
