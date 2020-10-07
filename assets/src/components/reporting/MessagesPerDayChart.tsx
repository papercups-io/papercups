import React from 'react';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from 'recharts';
import {colors} from '../common';

// Display messages and conversations per day in this chart
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

export default MessagesPerDayChart;
