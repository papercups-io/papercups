import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import {range} from 'lodash';
import qs from 'query-string';
import {env} from './config';
import {Message, User} from './types';

dayjs.extend(utc);

const {REACT_APP_STRIPE_PUBLIC_KEY} = env;

export const sleep = (ms: number) => new Promise((res) => setTimeout(res, ms));

export const noop = () => {};

export const hasValidStripeKey = () => {
  const key = REACT_APP_STRIPE_PUBLIC_KEY;

  return key && key.startsWith('pk_');
};

export const isValidEmail = (email?: string | null) => {
  if (!email) {
    return false;
  }
  // Super basic validation: https://stackoverflow.com/a/4964763
  return /(.+)@(.+){2,}\.(.+){2,}/.test(email);
};

export const formatUserExternalId = ({id, email}: User) => {
  return [id, email].join('|');
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

export const formatShortRelativeTime = (date: dayjs.Dayjs) => {
  const seconds = dayjs().diff(date, 'second');
  const mins = Math.floor(seconds / 60);
  const hrs = Math.floor(mins / 60);
  const days = Math.floor(hrs / 24);

  if (seconds < 60) {
    return `${seconds}s`;
  } else if (mins <= 60) {
    return `${mins}m`;
  } else if (hrs <= 24) {
    return `${hrs}h`;
  } else {
    return `${days}d`;
  }
};

export const formatDiffDuration = (start: dayjs.Dayjs, finish: dayjs.Dayjs) => {
  const diff = finish.diff(start, 's');
  const seconds = diff % 60;
  const mins = Math.floor(diff / 60) % 60;
  const hrs = Math.floor(diff / 60 / 60);
  const format = (n: number) => String(n).padStart(2, '0');

  return `${format(hrs)}:${format(mins)}:${format(seconds)}`;
};

export const formatSecondsToHoursAndMinutes = (secs: number) => {
  // time would look like 00:01:20 if on average it takes 80.3 seconds to respond
  const time = new Date(Math.round(secs) * 1000)
    .toISOString()
    .substring(11, 19);
  const [hours, minutes, seconds] = time.split(':');

  return {hours, minutes, seconds};
};

const defaultFormatterFn = (n: number) => String(n).padStart(2, '0');

export const formatSecondsToHoursAndMinutesV2 = (
  secs: number,
  formatter = defaultFormatterFn
) => {
  const seconds = secs % 60;
  const minutes = Math.floor(secs / 60) % 60;
  const hours = Math.floor(secs / 60 / 60);

  return {
    hours: formatter(hours),
    minutes: formatter(minutes),
    seconds: formatter(seconds),
  };
};

export const isValidUuid = (id: any) => {
  if (!id || typeof id !== 'string' || !id.length) {
    return false;
  }

  const regex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-5][0-9a-f]{3}-[089ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

  return regex.test(id);
};

export const generateDateRange = (
  start: dayjs.Dayjs,
  finish: dayjs.Dayjs
): Array<dayjs.Dayjs> => {
  const diff = finish.endOf('day').diff(start.startOf('day'), 'day');

  return range(diff + 1).map((n) => {
    return start.add(n, 'day');
  });
};

export const sortConversationMessages = (messages: Array<Message>) => {
  return messages.sort((a: Message, b: Message) => {
    // NB: `created_at` is stored as UTC implicitly, whereas `sent_at` is stored
    // as UTC explicitly. This means that we have to convert `created_at` to a
    // UTC date on the frontend first in order to compare the two properly.

    // FIXME: there are issues where `sent_at` may be set a few minutes to an hour
    // ahead of `created_at` for some reason. For now, we only sort by `sent_at` if
    // it comes before `created_at`, since that is the expected behavior.
    // (i.e. `sent_at` is the timestamp set in the client before it's sent to the server)

    const sentAtA = a.sent_at ? +new Date(a.sent_at) : null;
    const sentAtB = b.sent_at ? +new Date(b.sent_at) : null;
    const createdAtA = +dayjs.utc(a.created_at).toDate();
    const createdAtB = +dayjs.utc(b.created_at).toDate();

    const dateA = sentAtA && sentAtA < createdAtA ? sentAtA : createdAtA;
    const dateB = sentAtB && sentAtB < createdAtB ? sentAtB : createdAtB;

    return dateA - dateB;
  });
};

export const updateQueryParams = (query: Record<any, any>) => {
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

export const formatServerError = (err: any) => {
  try {
    const error = err?.response?.body?.error ?? {};
    const {errors = {}, message, status} = error;

    if (status === 422 && Object.keys(errors).length > 0) {
      const messages = Object.keys(errors)
        .map((field) => {
          const description = errors[field];

          if (description) {
            return `${field} ${description}`;
          } else {
            return `invalid ${field}`;
          }
        })
        .join(', ');

      return `Error: ${messages}.`;
    } else {
      return (
        message ||
        err?.message ||
        'Something went wrong. Please contact us or try again in a few minutes.'
      );
    }
  } catch {
    return (
      err?.response?.body?.error?.message ||
      err?.message ||
      'Something went wrong. Please contact us or try again in a few minutes.'
    );
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

export const isScrolledIntoView = (el: any) => {
  if (!el) {
    return false;
  }

  const rect = el.getBoundingClientRect();
  const {top, bottom} = rect;
  const isVisible = top >= 0 && bottom <= window.innerHeight;

  return isVisible;
};

export const download = (data = {}, name = 'data') => {
  // Taken from https://stackoverflow.com/a/55613750
  const json = JSON.stringify(data, null, 2);
  const blob = new Blob([json], {type: 'application/json'});
  const href = URL.createObjectURL(blob);
  const link = document.createElement('a');

  link.href = href;
  link.download = `${name}-${+new Date()}.json`;

  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
};
