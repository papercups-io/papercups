import dayjs from 'dayjs';
import {
  formatRelativeTime,
  formatDiffDuration,
  formatSecondsToHoursAndMinutes,
  formatSecondsToHoursAndMinutesV2,
} from './utils';

describe('formatRelativeTime', () => {
  test('handles seconds correctly', () => {
    const day = dayjs().subtract(10, 'second');

    expect(formatRelativeTime(day)).toEqual('10 seconds ago');
  });

  test('handles minutes correctly', () => {
    const day = dayjs().subtract(150, 'second');

    expect(formatRelativeTime(day)).toEqual('2 minutes ago');
  });

  test('handles hours correctly', () => {
    const day = dayjs().subtract(90, 'minute');

    expect(formatRelativeTime(day)).toEqual('1 hour ago');
  });

  test('handles hours correctly', () => {
    const day = dayjs().subtract(100, 'hour');

    expect(formatRelativeTime(day)).toEqual('4 days ago');
  });
});

describe('formatDiffDuration', () => {
  test('handles seconds correctly', () => {
    const start = dayjs();
    const finish = dayjs().add(10, 'second');

    expect(formatDiffDuration(start, finish)).toEqual('00:00:10');
  });

  test('handles minutes correctly', () => {
    const start = dayjs();
    const finish = dayjs().add(205, 'second');

    expect(formatDiffDuration(start, finish)).toEqual('00:03:25');
  });

  test('handles hours correctly', () => {
    const start = dayjs();
    const finish = dayjs().add(400, 'minute');

    expect(formatDiffDuration(start, finish)).toEqual('06:40:00');
  });
});

describe('formatSecondsToHoursAndMinutes', () => {
  test('handles seconds correctly', () => {
    expect(formatSecondsToHoursAndMinutes(0)).toEqual({
      hours: '00',
      minutes: '00',
      seconds: '00',
    });

    expect(formatSecondsToHoursAndMinutes(50)).toEqual({
      hours: '00',
      minutes: '00',
      seconds: '50',
    });
  });

  test('handles minutes correctly', () => {
    expect(formatSecondsToHoursAndMinutes(60)).toEqual({
      hours: '00',
      minutes: '01',
      seconds: '00',
    });

    expect(formatSecondsToHoursAndMinutes(80)).toEqual({
      hours: '00',
      minutes: '01',
      seconds: '20',
    });
  });

  test('handles hours correctly', () => {
    expect(formatSecondsToHoursAndMinutes(3600)).toEqual({
      hours: '01',
      minutes: '00',
      seconds: '00',
    });

    expect(formatSecondsToHoursAndMinutes(4000)).toEqual({
      hours: '01',
      minutes: '06',
      seconds: '40',
    });
  });
});

describe('formatSecondsToHoursAndMinutesV2', () => {
  test('handles seconds correctly', () => {
    expect(formatSecondsToHoursAndMinutesV2(0)).toEqual({
      hours: '00',
      minutes: '00',
      seconds: '00',
    });

    expect(formatSecondsToHoursAndMinutesV2(50)).toEqual({
      hours: '00',
      minutes: '00',
      seconds: '50',
    });
  });

  test('handles minutes correctly', () => {
    expect(formatSecondsToHoursAndMinutesV2(60)).toEqual({
      hours: '00',
      minutes: '01',
      seconds: '00',
    });

    expect(formatSecondsToHoursAndMinutesV2(80)).toEqual({
      hours: '00',
      minutes: '01',
      seconds: '20',
    });
  });

  test('handles hours correctly', () => {
    expect(formatSecondsToHoursAndMinutesV2(3600)).toEqual({
      hours: '01',
      minutes: '00',
      seconds: '00',
    });

    expect(formatSecondsToHoursAndMinutesV2(4000)).toEqual({
      hours: '01',
      minutes: '06',
      seconds: '40',
    });
  });
});
