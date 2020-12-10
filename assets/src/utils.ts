import dayjs from 'dayjs';
import qs from 'query-string';

const {REACT_APP_STRIPE_PUBLIC_KEY} = process.env;

export const sleep = (ms: number) => new Promise((res) => setTimeout(res, ms));

export const hasValidStripeKey = () => {
  const key = REACT_APP_STRIPE_PUBLIC_KEY;

  return key && key.startsWith('pk_');
};

export const formatRelativeTime = (date: dayjs.Dayjs) => {
  const seconds = dayjs().diff(date, 'second');
  const mins = Math.floor(seconds / 60);
  const hrs = Math.floor(mins / 60);
  const days = Math.floor(hrs / 24);

  if (seconds < 10) {
    return 'just now';
  } else if (seconds < 60) {
    return `${seconds} seconds ago`;
  } else if (mins <= 60) {
    return `${mins} minute${mins === 1 ? '' : 's'} ago`;
  } else if (hrs <= 24) {
    return `${hrs} hour${hrs === 1 ? '' : 's'} ago`;
  } else {
    return `${days} day${days === 1 ? '' : 's'} ago`;
  }
};

export const formatDiffDuration = (start: dayjs.Dayjs, finish: dayjs.Dayjs) => {
  const diff = finish.diff(start, 's');
  const seconds = diff % 60;
  const mins = Math.floor(diff / 60) % 60;
  const hrs = Math.floor(mins / 60);
  const format = (n: number) => String(n).padStart(2, '0');

  return `${format(hrs)}:${format(mins)}:${format(seconds)}`;
};

export const isValidUuid = (id: any) => {
  if (!id || typeof id !== 'string' || !id.length) {
    return false;
  }

  const regex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-5][0-9a-f]{3}-[089ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

  return regex.test(id);
};

export const updateQueryParams = (query: object) => {
  if (window.history.pushState) {
    window.history.pushState(
      null,
      '',
      `${window.location.pathname}?${qs.stringify(query)}`
    );
  } else {
    console.warn('`window.history.pushState` is not available!');
  }
};

export const getBrowserVisibilityInfo = (document: any) => {
  if (typeof document.hidden !== 'undefined') {
    return {
      hidden: 'hidden',
      event: 'visibilitychange',
      state: 'visibilityState',
    };
  } else if (typeof document.mozHidden !== 'undefined') {
    return {
      hidden: 'mozHidden',
      event: 'mozvisibilitychange',
      state: 'mozVisibilityState',
    };
  } else if (typeof document.msHidden !== 'undefined') {
    return {
      hidden: 'msHidden',
      event: 'msvisibilitychange',
      state: 'msVisibilityState',
    };
  } else if (typeof document.webkitHidden !== 'undefined') {
    return {
      hidden: 'webkitHidden',
      event: 'webkitvisibilitychange',
      state: 'webkitVisibilityState',
    };
  } else {
    return {
      hidden: null,
      event: null,
      state: null,
    };
  }
};

export const isWindowHidden = (document: any): boolean => {
  const {hidden} = getBrowserVisibilityInfo(document);

  return hidden ? !!document[hidden] : false;
};

export const addVisibilityEventListener = (
  document: any,
  handler: (e: any) => void
) => {
  const {event} = getBrowserVisibilityInfo(document);

  document.addEventListener(event, handler, false);

  return () => document.removeEventListener(event, handler);
};
