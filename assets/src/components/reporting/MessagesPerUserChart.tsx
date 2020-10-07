import React from 'react';
import {useState} from 'react';
import {PieChart, Pie, Cell, Sector, ResponsiveContainer} from 'recharts';
import {colors} from '../common';
import {FAKE_DATA_USERS} from './support';

const COLORS = [colors.green, colors.gold, colors.red, colors.volcano];

// down by "sent" vs "received" (where "sent" is outbound, "received" is inbound)

const renderActiveShape = (props: any) => {
  const RADIAN = Math.PI / 180;
  const {
    cx,
    cy,
    midAngle,
    innerRadius,
    outerRadius,
    startAngle,
    endAngle,
    fill,
    value,
    name,
  } = props;
  const sin = Math.sin(-RADIAN * midAngle);
  const cos = Math.cos(-RADIAN * midAngle);
  const sx = cx + (outerRadius + 10) * cos;
  const sy = cy + (outerRadius + 10) * sin;
  const mx = cx + (outerRadius + 30) * cos;
  const my = cy + (outerRadius + 30) * sin;
  const ex = mx + (cos >= 0 ? 1 : -1) * 22;
  const ey = my;
  const textAnchor = cos >= 0 ? 'start' : 'end';
  return (
    <g>
      <Sector
        cx={cx}
        cy={cy}
        innerRadius={innerRadius}
        outerRadius={outerRadius + 10}
        startAngle={startAngle}
        endAngle={endAngle}
        fill={fill}
      />
      <Sector
        cx={cx}
        cy={cy}
        startAngle={startAngle}
        endAngle={endAngle}
        innerRadius={outerRadius + 6}
        outerRadius={outerRadius + 10}
        fill={fill}
      />
      <path
        d={`M${sx},${sy}L${mx},${my}L${ex},${ey}`}
        stroke={fill}
        fill="none"
      />
      <circle cx={ex} cy={ey} r={2} fill={fill} stroke="none" />
      <text
        x={ex + (cos >= 0 ? 1 : -1) * 12}
        y={ey}
        textAnchor={textAnchor}
        fill={'#686D76'}
      >{`${name}`}</text>
      <text
        x={ex + (cos >= 0 ? 1 : -1) * 12}
        y={ey}
        dy={30}
        textAnchor={textAnchor}
        fill={fill}
      >{`Messages : ${value}`}</text>
    </g>
  );
};

const MessagesPerUserChart = ({data = FAKE_DATA_USERS}: {data: any}) => {
  const [activeindex, setActiveindex] = useState(-1);

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
          data={data}
          innerRadius={60}
          outerRadius={75}
          fill="#8884d8"
          paddingAngle={5}
          dataKey="value"
          activeShape={renderActiveShape}
          onMouseEnter={(data, index) => {
            setActiveindex(index);
          }}
          onMouseLeave={(data, index) => {
            setActiveindex(-1);
          }}
          activeIndex={activeindex}
        >
          {data.map((entry: any, index: number) => (
            <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
          ))}
        </Pie>
      </PieChart>
    </ResponsiveContainer>
  );
};

export default MessagesPerUserChart;
