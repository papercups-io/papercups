import React from 'react';
import {Box, Flex} from 'theme-ui';
import {notification, Button, Input, Popconfirm, Table, Text} from '../common';
import {PersonalApiKey} from '../../types';

const ApiKeyInput = ({value}: {value: string}) => {
  const [isRevealed, setRevealed] = React.useState(false);
  const ref = React.useRef<any>(null);

  const highlightAndCopyInput = () => {
    const input = ref.current;

    if (!input) {
      return;
    }

    input.focus();

    // NB: Not sure why the setTimeout is necessary here, but seems to not work otherwise...
    setTimeout(() => {
      input.select();

      if (document.queryCommandSupported('copy')) {
        document.execCommand('copy');
        notification.open({
          message: 'Copied to clipboard!',
          description: 'Please be sure to keep your API keys secret.',
        });
      }
    });
  };

  const toggle = () => {
    if (isRevealed) {
      setRevealed(false);
    } else {
      setRevealed(true);
      highlightAndCopyInput();
    }
  };

  return (
    <Flex>
      <Input ref={ref} type={isRevealed ? 'text' : 'password'} value={value} />
      <Box ml={1}>
        <Button onClick={toggle}>{isRevealed ? 'Hide' : 'Reveal'}</Button>
      </Box>
    </Flex>
  );
};

const PersonalApiKeysTable = ({
  personalApiKeys,
  onDeleteApiKey,
}: {
  personalApiKeys: Array<PersonalApiKey>;
  onDeleteApiKey: (personalApiKey: PersonalApiKey) => void;
}) => {
  const columns = [
    {
      title: 'Label',
      dataIndex: 'label',
      key: 'label',
      render: (value: string, record: any) => {
        return <Text>{value}</Text>;
      },
    },
    {
      title: 'API key',
      dataIndex: 'value',
      key: 'value',
      flex: 1,
      render: (value: string) => {
        return <ApiKeyInput value={value} />;
      },
    },

    {
      title: '',
      dataIndex: 'action',
      key: 'action',
      render: (action: any, record: any) => {
        return (
          <Flex sx={{justifyContent: 'center'}}>
            <Popconfirm
              title="Are you sure you want to delete this API key?"
              okText="Yes"
              cancelText="No"
              placement="topLeft"
              onConfirm={() => onDeleteApiKey(record)}
            >
              <Button danger>Delete API key</Button>
            </Popconfirm>
          </Flex>
        );
      },
    },
  ];

  return (
    <Table
      rowKey="id"
      dataSource={personalApiKeys}
      columns={columns}
      pagination={false}
    />
  );
};

export default PersonalApiKeysTable;
