import React from 'react';
import {Flex} from 'theme-ui';
import dayjs from 'dayjs';
import {colors, Button, Table, Tag, Text} from '../common';
import {SmileTwoTone} from '../icons';
import {User, Alignment} from '../../types';

const AccountUsersTable = ({
  loading,
  users,
  currentUser,
  isAdmin,
  onDisableUser,
}: {
  loading?: boolean;
  users: Array<User>;
  currentUser: User;
  isAdmin?: boolean;
  onDisableUser: (user: User) => void;
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
        if (currentUser && record.id === currentUser.id) {
          return (
            <Flex sx={{alignItems: 'center'}}>
              <Text strong>{value}</Text>
              <SmileTwoTone
                style={{fontSize: 16, marginLeft: 4}}
                twoToneColor={colors.primary}
              />
            </Flex>
          );
        }

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
      title: 'Role',
      dataIndex: 'role',
      key: 'role',
      render: (value: string) => {
        switch (value) {
          case 'admin':
            return <Tag color={colors.green}>Admin</Tag>;
          case 'user':
            return <Tag>Member</Tag>;
          default:
            return '--';
        }
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

        // Current user cannot disable themselves
        if (currentUser && record.id === currentUser.id) {
          return null;
        }

        return (
          <Button danger onClick={() => onDisableUser(record)}>
            Disable
          </Button>
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

export default AccountUsersTable;
