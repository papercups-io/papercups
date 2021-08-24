import React from 'react';
import dayjs from 'dayjs';
import {Button, Dropdown, Menu, Table} from '../common';
import {SettingOutlined} from '../icons';
import {User, Alignment} from '../../types';

const DisabledUsersTable = ({
  loading,
  users,
  isAdmin,
  onEnableUser,
  onArchiveUser,
}: {
  loading?: boolean;
  users: Array<User>;
  isAdmin?: boolean;
  onEnableUser: (user: User) => void;
  onArchiveUser: (user: User) => void;
}) => {
  // TODO: how should we sort the users?
  const data = users.map((u) => {
    return {...u, key: u.id};
  });

  const columns = [
    {
      title: 'Email',
      dataIndex: 'email',
      key: 'email',
      render: (value: string, record: User) => {
        return value;
      },
    },
    {
      title: 'Name',
      dataIndex: 'name',
      key: 'name',
      render: (value: string, record: User) => {
        const {full_name: fullName, display_name: displayName} = record;

        return fullName || displayName || '--';
      },
    },
    {
      title: 'Member since',
      dataIndex: 'created_at',
      key: 'created_at',
      render: (value: string) => {
        const formatted = dayjs(value).format('MMMM DD, YYYY');

        return formatted;
      },
    },
    {
      title: 'Disabled on',
      dataIndex: 'disabled_at',
      key: 'disabled_at',
      render: (value: string) => {
        const formatted = dayjs(value).format('MMMM DD, YYYY');

        return formatted;
      },
    },
    {
      title: '',
      dataIndex: 'action',
      key: 'action',
      align: Alignment.Right,
      render: (value: string, record: User) => {
        if (!isAdmin) {
          return null;
        }

        const handleMenuClick = (data: any) => {
          switch (data.key) {
            case 'enable':
              return onEnableUser(record);
            case 'archive':
              return onArchiveUser(record);
            default:
              return null;
          }
        };

        return (
          <Dropdown
            overlay={
              <Menu onClick={handleMenuClick}>
                <Menu.Item key="enable">Enable user</Menu.Item>
                <Menu.Item key="archive">Archive user</Menu.Item>
              </Menu>
            }
          >
            <Button icon={<SettingOutlined />} />
          </Dropdown>
        );
      },
    },
  ];

  return (
    <Table
      loading={loading}
      dataSource={data}
      columns={columns}
      pagination={false}
    />
  );
};

export default DisabledUsersTable;
