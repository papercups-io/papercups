import React from 'react';
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
import {colors, Alert, Paragraph, Text, Title} from '../common';

// Fake data for testing
const data = [
  {
    name: 'Sept 1',
    messages: 40,
    conversations: 24,
  },
  {
    name: 'Sept 2',
    messages: 30,
    conversations: 13,
  },
  {
    name: 'Sept 3',
    messages: 20,
    conversations: 9,
  },
  {
    name: 'Sept 4',
    messages: 27,
    conversations: 19,
  },
  {
    name: 'Sept 5',
    messages: 90,
    conversations: 30,
  },
  {
    name: 'Sept 6',
    messages: 23,
    conversations: 8,
  },
  {
    name: 'Sept 7',
    messages: 34,
    conversations: 12,
  },
];

const DemoLineChart = () => {
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
        <XAxis dataKey="name" />
        <YAxis />
        <Tooltip />
        <Legend />
        <Line
          type="monotone"
          dataKey="conversations"
          stroke={colors.primary}
          activeDot={{r: 8}}
        />
        <Line type="monotone" dataKey="messages" stroke={colors.green} />
      </LineChart>
    </ResponsiveContainer>
  );
};

const DemoBarChart = () => {
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
        <XAxis dataKey="name" />
        <YAxis />
        <Tooltip />
        <Legend />
        <Bar dataKey="messages" fill={colors.primary} />
        <Bar dataKey="conversations" fill={colors.green} />
      </BarChart>
    </ResponsiveContainer>
  );
};

type Props = {};
type State = {};

class ReportingDashboard extends React.Component<Props, State> {
  async componentDidMount() {
    //
  }

  render() {
    return (
      <Box p={4}>
        <Box mb={4}>
          <Title level={3}>Reporting</Title>

          <Paragraph>
            Analytics and statistics around user engagement.
          </Paragraph>
        </Box>

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

        <Flex mx={-3} sx={{maxWidth: 960}}>
          <Box mb={4} mx={3} sx={{height: 320, flex: 1}}>
            <DemoLineChart />
          </Box>
          <Box mb={4} mx={3} sx={{height: 320, flex: 1}}>
            <DemoBarChart />
          </Box>
        </Flex>
      </Box>
    );
  }
}

export default ReportingDashboard;
