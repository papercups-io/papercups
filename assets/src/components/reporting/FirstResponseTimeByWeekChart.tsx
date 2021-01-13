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

const FirstResponseTimeByWeekChart = ({data}: {data: any}) => {
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
        <XAxis dataKey="day"></XAxis>
        <YAxis width={40} name="minutes" />
        <Tooltip />
        <Legend />
        <Bar
          dataKey="average"
          fill={colors.primary}
          name="response time (minutes)"
        />
      </BarChart>
    </ResponsiveContainer>
  );
};

export default FirstResponseTimeByWeekChart;
