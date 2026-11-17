export interface AnalyticsOptions {
  endpoint?: string;
  project: string;
  /** Public event-ingestion key; never use an OAuth secret here. */
  key: string;
}
export interface AnalyticsClient {
  track(name: string, options?: {page?: string}): Promise<void>;
  pageView(page?: string): Promise<void>;
}
export function createAnalytics(options: AnalyticsOptions): AnalyticsClient;
