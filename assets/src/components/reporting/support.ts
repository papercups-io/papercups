export type ReportingDatum = {
  date: string;
  messages: number | null;
  conversations: number | null;
  sent?: number | null;
  received?: number | null;
};

// Fake data for testing
// TODO: replace with real data from API below!
export const FAKE_DATA_USERS: Array<any> = [
  {
    name: 'alex@gmail.com',
    value: 4,
  },
  {
    name: 'kam@gmail.com',
    value: 6,
  },
  {
    name: 'joe@gmail.com',
    value: 6,
  },
  {
    name: 'stepan@gmail.com',
    value: 7,
  },
  {
    name: 'emily@gmail.com',
    value: 4,
  },
];
export const FAKE_DATA: Array<ReportingDatum> = [
  {
    date: 'Sept 1',
    messages: 40,
    sent: 18,
    received: 22,
    conversations: 24,
  },
  {
    date: 'Sept 2',
    messages: 30,
    sent: 11,
    received: 19,
    conversations: 13,
  },
  {
    date: 'Sept 3',
    messages: 20,
    sent: 5,
    received: 15,
    conversations: 9,
  },
  {
    date: 'Sept 4',
    messages: 27,
    sent: 10,
    received: 17,
    conversations: 19,
  },
  {
    date: 'Sept 5',
    messages: 90,
    sent: 26,
    received: 64,
    conversations: 30,
  },
  {
    date: 'Sept 6',
    messages: 23,
    sent: 5,
    received: 18,
    conversations: 8,
  },
  {
    date: 'Sept 7',
    messages: 34,
    sent: 9,
    received: 25,
    conversations: 12,
  },
];
