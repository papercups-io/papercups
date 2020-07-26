import dayjs from 'dayjs';

export const sleep = (ms: number) => new Promise((res) => setTimeout(res, ms));

export const formatRelativeTime = (date: dayjs.Dayjs) => {
  const ms = dayjs().diff(date, 'second');
  const mins = Math.floor(ms / 60);
  const hrs = Math.floor(mins / 60);
  const days = Math.floor(hrs / 24);

  if (ms < 10) {
    return 'just now';
  } else if (ms < 60) {
    return `${ms} seconds ago`;
  } else if (mins <= 60) {
    return `${mins} minute${mins === 1 ? '' : 's'} ago`;
  } else if (hrs <= 24) {
    return `${hrs} hour${hrs === 1 ? '' : 's'} ago`;
  } else {
    return `${days} day${days === 1 ? '' : 's'} ago`;
  }
};
