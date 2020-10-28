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

const MessagesByDayOfWeekChart = ({data}: {data: any}) => {
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
        <XAxis dataKey="day" />
        <YAxis width={40} />
        <Tooltip />
        <Legend />
        <Bar dataKey="average" stackId="messages" fill={colors.magenta} />
        <Bar dataKey="total" stackId="messages" fill={colors.primary} />
      </BarChart>
    </ResponsiveContainer>
  );
};

export default MessagesByDayOfWeekChart;
