import React from 'react';
import dayjs from 'dayjs';
import {Box, Flex} from 'theme-ui';
import * as API from '../../api';
import {
  colors,
  Divider,
  Paragraph,
  RangePicker,
  Statistic,
  Text,
  Title,
} from '../common';
import MessagesPerDayChart from './MessagesPerDayChart';
import MessagesPerUserChart from './MessagesPerUserChart';
import MessagesSentVsReceivedChart from './MessagesSentVsReceivedChart';
import MessagesByDayOfWeekChart from './MessagesByDayOfWeekChart';
import {ReportingDatum} from './support';
import {formatSecondsToHoursAndMinutes} from '../../utils';
import logger from '../../logger';

type DateCount = {
  count: number;
  date: string;
};

type WeekdayCount = {
  average: number;
  total: number;
  day: string;
};

type MessageCount = {
  count: number;
  user: {
    email: string;
    id: number;
  };
};

interface CustomerBreakdownCount {
  count: number;
}

type ReplyTimeMetricsByWeek = {
  start_date: string;
  end_date: string;
  average: number;
  median: number;
  seconds_to_first_reply_list: Array<number>;
};

type Props = {};
type State = {
  fromDate: dayjs.Dayjs;
  toDate: dayjs.Dayjs;
  messagesByDate: Array<DateCount>;
  conversationsByDate: Array<DateCount>;
  messagesPerUser: Array<MessageCount>;
  receivedMessagesByDate: Array<DateCount>;
  sentMessagesByDate: Array<DateCount>;
  messagesByWeekday: Array<WeekdayCount>;
  customerBreakdownByBrowser: Array<CustomerBreakdownCount>;
  customerBreakdownByOs: Array<CustomerBreakdownCount>;
  customerBreakdownByTimezone: Array<CustomerBreakdownCount>;
  averageTimeToFirstReply: number;
  medianTimeToFirstReply: number;
  firstReplyMetricsByWeek: Array<ReplyTimeMetricsByWeek>;
};

class ReportingDashboard extends React.Component<Props, State> {
  state: State = {
    fromDate: dayjs().subtract(30, 'day'),
    toDate: dayjs(),
    messagesByDate: [],
    conversationsByDate: [],
    messagesPerUser: [],
    receivedMessagesByDate: [],
    sentMessagesByDate: [],
    messagesByWeekday: [],
    customerBreakdownByBrowser: [],
    customerBreakdownByOs: [],
    customerBreakdownByTimezone: [],
    averageTimeToFirstReply: 0,
    medianTimeToFirstReply: 0,
    firstReplyMetricsByWeek: [],
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
      messagesPerUser: data?.messages_per_user || [],
      receivedMessagesByDate: data?.received_messages_by_date || [],
      sentMessagesByDate: data?.sent_messages_by_date || [],
      messagesByWeekday: data?.messages_by_weekday || [],
      customerBreakdownByBrowser: data?.customer_breakdown_by_browser || [],
      customerBreakdownByOs: data?.customer_breakdown_by_os || [],
      customerBreakdownByTimezone: data?.customer_breakdown_by_time_zone || [],
      averageTimeToFirstReply: data?.average_time_to_first_reply || 0,
      medianTimeToFirstReply: data?.median_time_to_first_reply || 0,
      firstReplyMetricsByWeek: data?.first_reply_metrics_by_week || [],
    });
  };

  formatUserStats = () => {
    const {messagesPerUser = []} = this.state;

    return messagesPerUser.map((data) => ({
      name: data.user.email,
      value: data.count,
    }));
  };

  formatCustomerBreakdownStats = (stats: Array<any>, field: string) => {
    const MAX_NUM_SHOWN = 5;
    const formatted = stats
      .map((data) => ({
        name: data[field] || 'Unknown',
        value: data.count || 0,
      }))
      .sort((a, b) => b.value - a.value);

    if (formatted.length <= MAX_NUM_SHOWN) {
      return formatted;
    }

    const top = formatted.slice(0, MAX_NUM_SHOWN - 1);
    const other = formatted.slice(MAX_NUM_SHOWN - 1).reduce(
      (acc, data) => {
        return {...acc, value: acc.value + (data.value || 0)};
      },
      {name: 'Other', value: 0}
    );

    return top.concat(other);
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
    const {
      messagesByDate = [],
      conversationsByDate = [],
      receivedMessagesByDate = [],
      sentMessagesByDate = [],
    } = this.state;
    const messageCountByDate = this.groupCountByDate(messagesByDate);
    const conversationCountByDate = this.groupCountByDate(conversationsByDate);
    const receivedCountByDate = this.groupCountByDate(receivedMessagesByDate);
    const sentCountByDate = this.groupCountByDate(sentMessagesByDate);
    const keys = [
      ...Object.keys(messageCountByDate),
      ...Object.keys(conversationCountByDate),
      ...Object.keys(receivedCountByDate),
      ...Object.keys(sentCountByDate),
    ];
    const uniqs = [...new Set(keys)];

    return uniqs.map((date) => {
      return {
        date,
        messages: messageCountByDate[date] || 0,
        conversations: conversationCountByDate[date] || 0,
        sent: sentCountByDate[date] || 0,
        received: receivedCountByDate[date] || 0,
      };
    });
  };

  formatDayOfWeekStats = () => {
    const {messagesByWeekday = []} = this.state;

    return messagesByWeekday.map((data: WeekdayCount) => {
      return {...data, day: data.day.slice(0, 3)};
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

  formatDurationInSeconds = (secs: number) => {
    const {hours, minutes, seconds} = formatSecondsToHoursAndMinutes(secs);

    return `${hours}h ${minutes}m ${seconds}s`;
  };

  formatAverageResponseTimeThisWeek = () => {
    const {firstReplyMetricsByWeek = []} = this.state;
    const [current, next] = firstReplyMetricsByWeek;

    if (!current) {
      return {};
    }

    const {average: averageThisWeek} = current;

    if (!next) {
      return {
        title: this.formatDurationInSeconds(averageThisWeek),
        description: null,
      };
    }

    const {average: averageLastWeek} = next;
    const percentage =
      (averageThisWeek - averageLastWeek) / (averageLastWeek || 1);
    const sign = percentage < 0 ? '-' : '+';

    return {
      title: this.formatDurationInSeconds(averageThisWeek),
      description: (
        <Paragraph>
          <Text
            style={{color: percentage < 0 ? colors.green : colors.red}}
          >{`${sign}${Math.abs(percentage).toFixed(2)}%`}</Text>{' '}
          <Text type="secondary">from previous week</Text>
        </Paragraph>
      ),
    };
  };

  // TODO: DRY this up with function above
  formatMedianResponseTimeThisWeek = () => {
    const {firstReplyMetricsByWeek = []} = this.state;
    const [current, next] = firstReplyMetricsByWeek;

    if (!current) {
      return {};
    }

    const {median: medianThisWeek} = current;

    if (!next) {
      return {
        title: this.formatDurationInSeconds(medianThisWeek),
        description: null,
      };
    }

    const {median: medianLastWeek} = next;
    const percentage =
      (medianThisWeek - medianLastWeek) / (medianLastWeek || 1);
    const sign = percentage < 0 ? '-' : '+';

    return {
      title: this.formatDurationInSeconds(medianThisWeek),
      description: (
        <Paragraph>
          <Text
            style={{color: percentage < 0 ? colors.green : colors.red}}
          >{`${sign}${Math.abs(percentage).toFixed(2)}%`}</Text>{' '}
          <Text type="secondary">from previous week</Text>
        </Paragraph>
      ),
    };
  };

  render() {
    const {
      fromDate,
      toDate,
      averageTimeToFirstReply = 0,
      medianTimeToFirstReply = 0,
    } = this.state;
    const dailyStats = this.formatDailyStats();
    const userStats = this.formatUserStats();
    const dayOfWeekStats = this.formatDayOfWeekStats();
    const {
      title: thisWeekAverageTitle,
      description: thisWeekAverageSubtext,
    } = this.formatAverageResponseTimeThisWeek();
    const {
      title: thisWeekMedianTitle,
      description: thisWeekMedianSubtext,
    } = this.formatMedianResponseTimeThisWeek();

    return (
      <Box p={4} sx={{maxWidth: 1080}}>
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

        <Box>
          <Box mb={2}>
            <Text strong>Response Metrics</Text>
          </Box>
          <Box>
            <Flex mx={-3}>
              <Box mx={3} sx={{flex: 1}}>
                <Statistic
                  title="Average response time this week"
                  value={thisWeekAverageTitle}
                />
                <Text>{thisWeekAverageSubtext}</Text>
              </Box>

              <Box mx={3} sx={{flex: 1}}>
                <Statistic
                  title="Median response time this week"
                  value={thisWeekMedianTitle}
                />
                <Text>{thisWeekMedianSubtext}</Text>
              </Box>

              <Box mx={3} sx={{flex: 1}}>
                <Statistic
                  title="Average response time overall"
                  value={this.formatDurationInSeconds(averageTimeToFirstReply)}
                />
              </Box>

              <Box mx={3} sx={{flex: 1}}>
                <Statistic
                  title="Median response time overall"
                  value={this.formatDurationInSeconds(medianTimeToFirstReply)}
                />
              </Box>
            </Flex>
          </Box>
          <Divider />
          <Flex mx={-3} mb={4}>
            <Box mb={4} mx={3} sx={{height: 320, maxWidth: '50%', flex: 1}}>
              <Box mb={2}>
                <Text strong>New messages per day</Text>
              </Box>
              <MessagesPerDayChart data={dailyStats} />
            </Box>

            <Box mb={4} mx={3} sx={{height: 320, maxWidth: '50%', flex: 1}}>
              <Box mb={2}>
                <Text strong>Messages sent vs received</Text>
              </Box>
              <MessagesSentVsReceivedChart data={dailyStats} />
            </Box>
          </Flex>

          <Flex mx={-3} mb={4}>
            <Box mb={4} mx={3} sx={{height: 320, maxWidth: '50%', flex: 1}}>
              <Box mb={2}>
                <Text strong>Messages per user</Text>
              </Box>
              <MessagesPerUserChart data={userStats} />
            </Box>

            <Box mb={4} mx={3} sx={{height: 320, maxWidth: '50%', flex: 1}}>
              <Box mb={2}>
                <Text strong>Messages by day of week</Text>
              </Box>
              <MessagesByDayOfWeekChart data={dayOfWeekStats} />
            </Box>
          </Flex>

          {/* Hiding customer breakdown charts for now since they aren't particularly useful ¯\_(ツ)_/¯ */}
          {/*
          <Divider />

          <Box my={4}>
            <Title level={3}>Customer breakdown</Title>
          </Box>

          <Flex mx={-3} mb={4}>
            <Box mb={4} mx={3} sx={{height: 280, maxWidth: '30%', flex: 1}}>
              <Box mb={2}>
                <Text strong>By browser</Text>
              </Box>
              <CustomerBreakdownChart data={browserStats} />
            </Box>

            <Box mb={4} mx={3} sx={{height: 280, maxWidth: '30%', flex: 1}}>
              <Box mb={2}>
                <Text strong>By operating system</Text>
              </Box>
              <CustomerBreakdownChart data={osStats} />
            </Box>

            <Box mb={4} mx={3} sx={{height: 280, maxWidth: '30%', flex: 1}}>
              <Box mb={2}>
                <Text strong>By timezone</Text>
              </Box>
              <CustomerBreakdownChart data={timezoneStats} />
            </Box>
          </Flex>
          */}
        </Box>
      </Box>
    );
  }
}

export default ReportingDashboard;
