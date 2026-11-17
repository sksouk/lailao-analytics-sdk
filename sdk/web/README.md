# Lailao Analytics

Small ESM client for explicit event tracking in browsers, React and Next.js.
Includes TypeScript types and an optional React route component. No runtime
network dependencies, install scripts, automatic page tracking, or cookies.

## Install

```sh
npm install @sksouk/lailao-analytics
```

```js
import {createAnalytics} from '@sksouk/lailao-analytics';
const analytics = createAnalytics({
  project: 'YOUR_PROJECT_ID',
  key: 'YOUR_SDK_WRITE_KEY',
  // endpoint defaults to https://analytics.lailaolab.com
});
await analytics.pageView();
await analytics.track('checkout_started', {page: '/checkout'});
```

Get your project ID and ingestion-only key from your Lailao Analytics workspace.
Never pass a Google client secret or dashboard credential into this client.

## React Router

Create one client outside your component, then mount once inside your router:

```jsx
import {useLocation} from 'react-router-dom';
import {createAnalytics} from '@sksouk/lailao-analytics';
import {AnalyticsPageView} from '@sksouk/lailao-analytics/react';
const analytics = createAnalytics({project: 'YOUR_PROJECT_ID', key: 'YOUR_SDK_WRITE_KEY'});
export function Tracking() {
  const {pathname} = useLocation();
  return <AnalyticsPageView analytics={analytics} pathname={pathname} onError={console.warn} />;
}
```

## Next.js App Router

```jsx
'use client';
import {usePathname} from 'next/navigation';
import {createAnalytics} from '@sksouk/lailao-analytics';
import {AnalyticsPageView} from '@sksouk/lailao-analytics/react';
const analytics = createAnalytics({project: 'YOUR_PROJECT_ID', key: 'YOUR_SDK_WRITE_KEY'});
export default function Tracking() {
  const pathname = usePathname();
  return <AnalyticsPageView analytics={analytics} pathname={pathname} onError={console.warn} />;
}
```

Mount `Tracking` once in the app layout. Importing/constructing the core client
is safe during SSR; events are sent only in the browser when a method is called.
The optional React component requires React 18 or 19. Plain Web use has no React dependency.

## Data and consent

Events include a random project-scoped visitor ID stored in localStorage, event
name, page path, external referrer hostname and the Web platform marker. The
server observes network IP. Do not send passwords, payment details, emails or
personal information in event names/page paths. Call tracking only after any
consent required by your app. The client does not manage consent, queue events,
retry rejected requests, track engagement automatically, or collect device details.
Failures reject the returned Promise; catch them without interrupting your UI.

## Local package verification

From this directory run `npm test` and `npm pack --dry-run`. Before the registry
release you can use `npm pack` and install its local tarball in a test project.
This package is MIT licensed. Source and release history are in the linked repository.
