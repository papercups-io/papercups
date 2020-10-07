import React from 'react';
import dayjs from 'dayjs';
import {Box, Flex} from 'theme-ui';
import * as API from '../../api';
import {Alert, Paragraph, RangePicker, Text, Title} from '../common';
import MessagesPerDayChart from './MessagesPerDayChart';
import {ReportingDatum} from './support';
import logger from '../../logger';

type DateCount = {
  count: number;
  date: string;
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

    this.setState({
      messagesByDate: data?.messages_by_date || [],
      conversationsByDate: data?.conversations_by_date || [],
    });
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
              <Text strong>New messages per day</Text>
            </Box>
            <MessagesPerDayChart data={this.formatDailyStats()} />
          </Box>
          {/*
          // TODO: implement me!

          <Box mb={4} mx={3} sx={{height: 320, flex: 1}}>
            <Box mb={2}>
              <Text strong>Messages sent vs received</Text>
            </Box>
            <MessagesSentVsReceivedChart data={...} />
          </Box>
          */}

          {/*
          // TODO: implement me!

          <Box mb={4} mx={3} sx={{height: 320, flex: 1}}>
            <Box mb={2}>
              <Text strong>Messages by day of week</Text>
            </Box>
            <MessagesByDayOfWeekChart data={...} />
          </Box>
          */}

          {/*
          // TODO: implement me!

          <Box mb={4} mx={3} sx={{height: 320, flex: 1}}>
            <Box mb={2}>
              <Text strong>Messages per user</Text>
            </Box>
            <MessagesPerUserChart data={...} />
          </Box>
          */}
        </Flex>
      </Box>
    );
  }
}

export default ReportingDashboard;
