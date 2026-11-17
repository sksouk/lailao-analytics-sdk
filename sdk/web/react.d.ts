import type {AnalyticsClient} from './index.js';
export function AnalyticsPageView(props: {
  analytics: AnalyticsClient;
  pathname: string;
  onError?: (error: unknown) => void;
}): null;
