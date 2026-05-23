// Background service worker — polls Claude usage API and bridges to local server.
// The server writes usage.json which the Claude Code hook reads.

const USAGE_API_BASE = 'https://claude.ai/api/organizations';
const BRIDGE_URL = 'http://127.0.0.1:2999/usage';
const POLL_MINUTES = 1;

chrome.runtime.onMessage.addListener((msg) => {
  if (msg.type === 'SET_ORG_ID' && msg.orgId) {
    chrome.storage.local.get('orgId').then(({ orgId }) => {
      if (orgId !== msg.orgId) {
        chrome.storage.local.set({ orgId: msg.orgId });
      }
      pollUsage(msg.orgId);
    });
  }
});

chrome.alarms.onAlarm.addListener((alarm) => {
  if (alarm.name === 'poll-usage') {
    chrome.storage.local.get('orgId').then(({ orgId }) => {
      if (orgId) pollUsage(orgId);
    });
  }
});

chrome.runtime.onInstalled.addListener(init);
chrome.runtime.onStartup.addListener(init);

async function init() {
  chrome.alarms.create('poll-usage', { periodInMinutes: POLL_MINUTES });
  const { orgId } = await chrome.storage.local.get('orgId');
  if (orgId) pollUsage(orgId);
}

async function pollUsage(orgId) {
  try {
    const res = await fetch(`${USAGE_API_BASE}/${orgId}/usage`, {
      credentials: 'include'
    });
    if (!res.ok) {
      console.warn('[claude-usage] API returned', res.status);
      return;
    }
    const data = await res.json();
    const payload = { ...data, _org_id: orgId, _fetched_at: new Date().toISOString() };
    await chrome.storage.local.set({ lastUsage: payload });
    await bridgeToServer(payload);
  } catch (e) {
    console.warn('[claude-usage] poll failed:', e.message);
  }
}

async function bridgeToServer(payload) {
  try {
    await fetch(BRIDGE_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });
  } catch (e) {
    // Server not running — data still saved in chrome.storage.local
    console.warn('[claude-usage] bridge server unreachable:', e.message);
  }
}
