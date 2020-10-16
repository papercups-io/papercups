import dayjs from 'dayjs';

export const sleep = (ms: number) => new Promise((res) => setTimeout(res, ms));

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
