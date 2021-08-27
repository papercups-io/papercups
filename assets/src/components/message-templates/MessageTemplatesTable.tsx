import React from 'react';
import {Link} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import {Button, Table} from '../common';
import {MessageTemplate} from '../../types';

export const MessageTemplatesTable = ({
  loading,
  isSelectEnabled,
  messageTemplates,
  onSelect,
}: {
  loading?: boolean;
  isSelectEnabled?: boolean;
  messageTemplates: Array<MessageTemplate>;
  onSelect: (id: string) => void;
}) => {
  const data = messageTemplates
    .map((messageTemplate) => {
      return {key: messageTemplate.id, ...messageTemplate};
    })
    .sort((a, b) => {
      return +new Date(b.updated_at) - +new Date(a.updated_at);
    });

  const columns = [
    {
      title: 'Name',
      dataIndex: 'name',
      key: 'name',
      render: (value: string) => {
        return value || '--';
      },
    },
    {
      title: 'Description',
      dataIndex: 'description',
      key: 'description',
      render: (value: string) => {
        return value || '--';
      },
    },
    {
      title: 'Last updated at',
      dataIndex: 'updated_at',
      key: 'updated_at',
      render: (value: string) => {
        return value || '--';
      },
    },
    {
      title: '',
      dataIndex: 'action',
      key: 'action',
      render: (value: string, record: any) => {
        const {id: messageTemplateId} = record;

        if (isSelectEnabled) {
          return (
            <Flex mx={-1} sx={{justifyContent: 'flex-end'}}>
              <Box mx={1}>
                <Link to={`/message-templates/${messageTemplateId}`}>
                  <Button>View</Button>
                </Link>
              </Box>
              <Box mx={1}>
                <Button
                  type="primary"
                  onClick={() => onSelect(messageTemplateId)}
                >
                  Select
                </Button>
              </Box>
            </Flex>
          );
        }

        return (
          <Flex sx={{justifyContent: 'flex-end'}}>
            <Link to={`/message-templates/${messageTemplateId}`}>
              <Button>View</Button>
            </Link>
          </Flex>
        );
      },
    },
  ];

  return <Table loading={loading} dataSource={data} columns={columns} />;
};

export default MessageTemplatesTable;
