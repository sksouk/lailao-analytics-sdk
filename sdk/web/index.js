/** Create an explicit, browser-side event client. No events are sent automatically. */
export function createAnalytics({endpoint = 'https://analytics.lailaolab.com', project, key} = {}) {
  if (typeof project !== 'string' || !project.trim() || typeof key !== 'string' || !key.trim()) {
    throw new TypeError('Lailao Analytics requires a project ID and SDK write key');
  }
  const base = new URL(endpoint);
  if (!['http:', 'https:'].includes(base.protocol) || base.username || base.password || base.search || base.hash) {
    throw new TypeError('Use an HTTP(S) analytics endpoint without credentials, query or fragment');
  }
  const eventsUrl = base.href.replace(/\/$/, '') + '/api/events';
  const storageKey = 'lailao-analytics:' + project;
  let visitor;
  async function track(name, {page = ''} = {}) {
    // Safe to import and construct during React/Next.js server rendering.
    if (typeof window === 'undefined' || typeof document === 'undefined') return;
    if (!visitor) {
      try {
        visitor = localStorage.getItem(storageKey);
        if (!visitor) { visitor = crypto.randomUUID(); localStorage.setItem(storageKey, visitor); }
      } catch { visitor ||= crypto.randomUUID(); }
    }
    let source = '(direct)';
    try {
      if (document.referrer) { const referrer = new URL(document.referrer); if (referrer.origin !== location.origin) source = referrer.hostname; }
    } catch { /* Invalid referrers do not prevent event delivery. */ }
    const response = await fetch(eventsUrl, {
      method: 'POST', headers: {'Content-Type': 'application/json'}, keepalive: true,
      body: JSON.stringify({id: crypto.randomUUID(), visitor, project, key, name, page, source, platform: 'Web'}),
    });
    if (!response.ok) throw new Error('Analytics event rejected (' + response.status + ')');
  }
  return {track, pageView: (page) => track('page_view', {page: page ?? (typeof location === 'undefined' ? '' : location.pathname)})};
}
