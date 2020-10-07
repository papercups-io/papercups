import React from 'react';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from 'recharts';
import {colors} from '../common';
import {FAKE_DATA} from './support';

// TODO: display messages and conversations in this chart with messages broken
// down by "sent" vs "received" (where "sent" is outbound, "received" is inbound)
const MessagesSentVsReceivedChart = ({data = FAKE_DATA}: {data: any}) => {
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

export default MessagesSentVsReceivedChart;
