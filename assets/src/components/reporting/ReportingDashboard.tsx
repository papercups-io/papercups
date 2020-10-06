import React from 'react';
import dayjs from 'dayjs';
import {Box, Flex} from 'theme-ui';
import {
  BarChart,
  Bar,
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from 'recharts';
import * as API from '../../api';
import {colors, Alert, Paragraph, RangePicker, Text, Title} from '../common';
import logger from '../../logger';

type ReportingDatum = {
  date: string;
  messages: number | null;
  conversations: number | null;
  sent?: number | null;
  received?: number | null;
};

type DateCount = {
  count: number;
  date: string;
};

// Fake data for testing
// TODO: replace with real data from API below!
const FAKE_DATA: Array<ReportingDatum> = [
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

// TODO: display messages and conversations per day in this chart
const MessagesPerDayChart = ({data}: {data: any}) => {
  return (
    <ResponsiveContainer>
      <LineChart
        data={data}
        margin={{
          top: 8,
          bottom: 8,
        }}
      >
        <CartesianGrid strokeDasharray="3 3" />
        <XAxis dataKey="date" />
        <YAxis width={40} />
        <Tooltip />
        <Legend />
        <Line
          type="monotone"
          dataKey="conversations"
          stroke={colors.magenta}
          activeDot={{r: 8}}
        />
        <Line type="monotone" dataKey="messages" stroke={colors.primary} />
      </LineChart>
    </ResponsiveContainer>
  );
};

// TODO: display messages and conversations in this chart with messages broken
// down by "sent" vs "received" (where "sent" is outbound, "received" is inbound)
const MessagesSentVsReceivedChart = ({data}: {data: any}) => {
  return (
    <ResponsiveContainer>
      <BarChart
        data={data}
        margin={{
          top: 8,
          bottom: 8,
        }}
      >
        <CartesianGrid strokeDasharray="3 3" />
        <XAxis dataKey="date" />
        <YAxis width={40} />
        <Tooltip />
        <Legend />
        <Bar dataKey="sent" stackId="messages" fill={colors.green} />
        <Bar dataKey="received" stackId="messages" fill={colors.primary} />
        <Bar dataKey="conversations" fill={colors.magenta} />
      </BarChart>
    </ResponsiveContainer>
  );
};

type Props = {};
type State = {
  fromDate: dayjs.Dayjs;
  toDate: dayjs.Dayjs;
  messagesByDate: Array<DateCount>;
  conversationsByDate: Array<DateCount>;
};

class ReportingDashboard extends React.Component<Props, State> {
  state: State = {
    fromDate: dayjs().subtract(30, 'day'),
    toDate: dayjs(),
    messagesByDate: [],
    conversationsByDate: [],
  };

  componentDidMount() {
    this.refreshReportingData().catch((err) =>
      logger.error('Failed to fetch reporting data:', err)
    );
  }

  refreshReportingData = async () => {
    const {fromDate, toDate} = this.state;
    const data = await API.fetchReportingData({
      from_date: fromDate.toISOString(),
      to_date: toDate.toISOString(),
    });

    logger.debug('Raw reporting data:', data);

    this.setState(
      {
        messagesByDate: data?.messages_by_date || [],
        conversationsByDate: data?.conversations_by_date || [],
      },
      () => {
        // TODO: remove this after implementing daily stats chart
        logger.debug('Formatted daily stats:', this.formatDailyStats());
      }
    );
  };

  groupCountByDate = (data: Array<DateCount>) => {
    return data
      .map(({date, count}) => ({date: dayjs(date).format('MMM D'), count}))
      .reduce(
        (acc, msg) => ({...acc, [msg.date]: msg.count}),
        {} as {[date: string]: number}
      );
  };

  formatDailyStats = (): Array<ReportingDatum> => {
    const {messagesByDate = [], conversationsByDate = []} = this.state;
    const messageCountByDate = this.groupCountByDate(messagesByDate);
    const conversationCountByDate = this.groupCountByDate(conversationsByDate);
    const keys = [
      ...Object.keys(messageCountByDate),
      ...Object.keys(conversationCountByDate),
    ];

    return keys.map((date) => {
      return {
        date,
        messages: messageCountByDate[date] || 0,
        conversations: conversationCountByDate[date] || 0,
      };
    });
  };

  handleDateRangeUpdated = (range: any) => {
    const [fromDate, toDate] = range;

    this.setState(
      {
        fromDate: dayjs(fromDate),
        toDate: dayjs(toDate),
      },
      () => this.refreshReportingData()
    );
  };

  render() {
    const {fromDate, toDate} = this.state;

    return (
      <Box p={4}>
        <Flex
          mb={4}
          sx={{justifyContent: 'space-between', alignItems: 'flex-end'}}
        >
          <Box>
            <Title level={3}>Reporting</Title>

            <Paragraph>
              Analytics and statistics around user engagement.
            </Paragraph>
          </Box>

          <Box mb={3}>
            <RangePicker
              value={[fromDate, toDate]}
              onChange={this.handleDateRangeUpdated}
            />
          </Box>
        </Flex>

        <Box mb={4}>
          <Alert
            message={
              <Text>
                This page is a work in progress! It's something we plan to set
                up for Hacktober Fest.
              </Text>
            }
            type="warning"
            showIcon
          />
        </Box>

        <Flex mx={-3} sx={{maxWidth: 1080}}>
          <Box mb={4} mx={3} sx={{height: 320, flex: 1}}>
            <Box mb={2}>
              <Text strong>Messages per day</Text>
            </Box>
            <MessagesPerDayChart data={FAKE_DATA} />
          </Box>
          <Box mb={4} mx={3} sx={{height: 320, flex: 1}}>
            <Box mb={2}>
              <Text strong>Messages sent vs received</Text>
            </Box>
            <MessagesSentVsReceivedChart data={FAKE_DATA} />
          </Box>
        </Flex>
      </Box>
    );
  }
}

export default ReportingDashboard;
