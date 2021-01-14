import React from 'react';
import {
  PieChart,
  Pie,
  Legend,
  Tooltip,
  Cell,
  ResponsiveContainer,
} from 'recharts';
import {colors} from '../common';

const {blues, purples, magentas} = colors;

const COLORS = [
  ...blues.slice(3).filter((c, i) => i % 2 === 1),
  ...purples.slice(3).filter((c, i) => i % 2 === 1),
  ...magentas.slice(3).filter((c, i) => i % 2 === 1),
];

const CustomerBreakdownChart = ({data}: {data: any}) => {
  return (
    <ResponsiveContainer>
      <PieChart
        margin={{
          top: 8,
          bottom: 8,
          left: 10,
          right: 10,
        }}
      >
        <Pie
          dataKey="value"
          isAnimationActive={false}
          data={data}
          startAngle={180}
          endAngle={0}
          cx="50%"
          cy="70%"
          outerRadius={80}
          fill={colors.primary}
          label={(props: any) => {
            const {
              cx,
              cy,
              midAngle,
              innerRadius,
              outerRadius,
              fill,
              value,
              name,
            } = props;
            const RADIAN = Math.PI / 180;
            const radius = 25 + innerRadius + (outerRadius - innerRadius);
            const x = cx + radius * Math.cos(-midAngle * RADIAN);
            const y = cy + radius * Math.sin(-midAngle * RADIAN);

            return (
              <text
                x={x}
                y={y}
                fill={fill}
                textAnchor={x > cx ? 'start' : 'end'}
                dominantBaseline="central"
              >
                {name} ({value})
              </text>
            );
          }}
        >
          {data.map((entry: any, index: number) => {
            return (
              <Cell
                key={`cell-${index}`}
                fill={COLORS[index % COLORS.length]}
              />
            );
          })}
        </Pie>
        <Tooltip />
        <Legend />
      </PieChart>
    </ResponsiveContainer>
  );
};

export default CustomerBreakdownChart;
