// Runs on claude.ai pages — extracts org ID and sends to background worker.
// Retries a few times in case DD_RUM loads after page ready.

let attempts = 0;

function tryGetOrgId() {
  attempts++;
  try {
    const orgId = window.DD_RUM?.getUser()?.organization_id;
    if (orgId) {
      chrome.runtime.sendMessage({ type: 'SET_ORG_ID', orgId });
      return;
    }
  } catch (e) {}

  // Fallback: extract from any in-page fetch that reveals org ID in URL
  // (covered by background webRequest interception via URL pattern matching)

  if (attempts < 10) {
    setTimeout(tryGetOrgId, 2000);
  }
}

if (document.readyState === 'complete') {
  tryGetOrgId();
} else {
  window.addEventListener('load', tryGetOrgId);
}
