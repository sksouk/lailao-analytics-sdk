'use client';
import {useEffect, useRef} from 'react';
/** Mount once inside your router and pass its current pathname. */
export function AnalyticsPageView({analytics, pathname, onError}) {
  const previous = useRef();
  const errorHandler = useRef(onError);
  errorHandler.current = onError;
  useEffect(() => {
    if (previous.current?.analytics === analytics && previous.current.pathname === pathname) return;
    previous.current = {analytics, pathname};
    analytics.pageView(pathname).catch(error => { if (errorHandler.current) errorHandler.current(error); });
  }, [analytics, pathname]);
  return null;
}
