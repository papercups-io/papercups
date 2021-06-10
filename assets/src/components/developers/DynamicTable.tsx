import React from 'react';
import {Table, Text} from '../common';
import {isObject} from 'lodash';

const DynamicTable = ({
  loading,
  data,
  includeArrayValues,
  includeObjectValues,
}: {
  loading?: boolean;
  data: Array<Record<string, any>>;
  includeArrayValues?: boolean;
  includeObjectValues?: boolean;
}) => {
  if (!Array.isArray(data)) {
    return null;
  }

  const keys = data.reduce((result, item) => {
    return Object.keys(item).reduce((acc, k) => {
      // Filter out array values
      if (!includeArrayValues && Array.isArray(item[k])) {
        return acc;
      } else if (!includeObjectValues && isObject(item[k])) {
        return acc;
      }

      return {...acc, [k]: true};
    }, result);
  }, {} as {[key: string]: boolean});

  const columns = Object.keys(keys).map((key, idx) => {
    return {
      title: key,
      dataIndex: key,
      key: key,
      render: (value: any) => {
        if (value == null) {
          return <Text type="secondary">--</Text>;
        } else if (isObject(value) || Array.isArray(value)) {
          return <Text>{JSON.stringify(value)}</Text>;
        } else {
          return <Text>{value}</Text>;
        }
      },
    };
  });

  return (
    <Table
      loading={loading}
      dataSource={data}
      columns={columns}
      scroll={{x: '100%'}}
    />
  );
};

export default DynamicTable;
