import React from 'react';
import {Link, RouteComponentProps} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';

import {Button, Card, Empty, Table, Text, Title} from '../common';
import * as API from '../../api';
import {Broadcast} from '../../types';
import logger from '../../logger';
import {SendOutlined} from '../icons';
import {formatBroadcastCustomers, formatDateTime} from './support';

// TODO: make it possible to select customer to preview in email template
const BroadcastCustomersTable = ({
  loading,
  customers,
  onSelectPreview,
}: {
  loading?: boolean;
  customers: Array<any>;
  onSelectPreview: (data: any) => void;
}) => {
  const data = customers
    .map((customer) => {
      return {key: customer.id, ...customer};
    })
    .sort((a, b) => {
      return +new Date(b.updated_at) - +new Date(a.updated_at);
    });

  const columns = [
    {
      title: 'Email',
      dataIndex: 'email',
      key: 'email',
      render: (email: string, record: any) => {
        const {name} = record;

        if (name) {
          return `${name} <${email}>`;
        } else {
          return email || '--';
        }
      },
    },
    {
      title: 'Sent at',
      dataIndex: 'sent_at',
      key: 'sent_at',
      render: (value: string) => {
        return value ? formatDateTime(value) : '--';
      },
    },
    {
      title: 'Status',
      dataIndex: 'state',
      key: 'state',
      render: (value: string) => {
        return value || '--';
      },
    },
  ];

  return (
    <Table
      loading={loading}
      dataSource={data}
      columns={columns}
      onRow={(record, idx) => {
        return {
          onClick: (event) => onSelectPreview(record), // click row
          // onMouseEnter: (event) => onSelectPreview(record), // mouse enter row
        };
      }}
    />
  );
};

type Props = RouteComponentProps<{id: string}>;
type State = {broadcast: Broadcast | null};

export class BroadcastDetailsPage extends React.Component<Props, State> {
  iframe: any = null;

  state: State = {broadcast: null};

  async componentDidMount() {
    const {id: broadcastId} = this.props.match.params;
    const broadcast = await API.fetchBroadcast(broadcastId);

    this.setState({broadcast}, () => this.handleUpdateIframe());
  }

  handleUpdateIframe = (data?: any) => {
    if (!this.state.broadcast) {
      return;
    }

    const {message_template: template} = this.state.broadcast;
    const html = template?.raw_html;
    const doc = this.iframe?.contentDocument;

    if (!html || !doc) {
      return;
    }

    doc.open();
    doc.write(html);
    doc.close();
  };

  handleSendBroadcast = async () => {
    try {
      const {id: broadcastId} = this.props.match.params;
      const broadcast = await API.sendBroadcastEmail(broadcastId);

      logger.info('Sent!', broadcast);
      this.setState({broadcast});
    } catch (err) {
      logger.error('Failed to send emails!', err);
    }
  };

  render() {
    const {broadcast} = this.state;

    if (!broadcast) {
      return null;
    }

    const {
      id: broadcastId,
      message_template: template,
      started_at: startedAt,
      finished_at: finishedAt,
      name,
      state,
    } = broadcast;
    const customers = formatBroadcastCustomers(broadcast);
    const isUnstarted = state === 'unstarted';
    const numCustomersSent = customers.filter((c) => !!c.sent_at).length;

    return (
      <Flex p={4} sx={{flex: 1, flexDirection: 'column'}}>
        <Flex
          mb={3}
          pb={3}
          sx={{
            justifyContent: 'space-between',
            alignItems: 'center',
            borderBottom: '1px solid rgba(0,0,0,.06)',
          }}
        >
          <Title level={2} style={{margin: 0}}>
            {name}
          </Title>
          {isUnstarted && (
            <Button
              type="primary"
              size="large"
              icon={<SendOutlined />}
              onClick={this.handleSendBroadcast}
            >
              Send broadcast
            </Button>
          )}
        </Flex>

        <Box py={3} mb={4}>
          <Card shadow="medium" px={4} py={3}>
            <Flex
              mx={-2}
              sx={{
                flexDirection: ['column', 'column', 'row'],
                justifyContent: 'space-between',
              }}
            >
              <Box mx={2}>
                <Box>
                  <Text style={{fontSize: 16}}>{state}</Text>
                </Box>
                <Text type="secondary" style={{fontSize: 12}}>
                  Status
                </Text>
              </Box>
              <Box mx={2}>
                <Box>
                  <Text style={{fontSize: 16}}>
                    {startedAt ? formatDateTime(startedAt) : '--'}
                  </Text>
                </Box>
                <Text type="secondary" style={{fontSize: 12}}>
                  Started at
                </Text>
              </Box>
              <Box mx={2}>
                <Box>
                  <Text style={{fontSize: 16}}>
                    {finishedAt ? formatDateTime(finishedAt) : '--'}
                  </Text>
                </Box>
                <Text type="secondary" style={{fontSize: 12}}>
                  Finished at
                </Text>
              </Box>
              <Box mx={2}>
                <Box>
                  <Text style={{fontSize: 16}}>{numCustomersSent}</Text>
                </Box>
                <Text type="secondary" style={{fontSize: 12}}>
                  Sent
                </Text>
              </Box>
              <Box mx={2}>
                <Box>
                  <Text style={{fontSize: 16}}>--</Text>
                </Box>
                <Text type="secondary" style={{fontSize: 12}}>
                  Delivered
                </Text>
              </Box>
              <Box mx={2}>
                <Box>
                  <Text style={{fontSize: 16}}>--</Text>
                </Box>
                <Text type="secondary" style={{fontSize: 12}}>
                  Bounced
                </Text>
              </Box>
              <Box mx={2}>
                <Box>
                  <Text style={{fontSize: 16}}>--</Text>
                </Box>
                <Text type="secondary" style={{fontSize: 12}}>
                  Unsubscribed
                </Text>
              </Box>
              <Box mx={2}>
                <Box>
                  <Text style={{fontSize: 16}}>--</Text>
                </Box>
                <Text type="secondary" style={{fontSize: 12}}>
                  Failed
                </Text>
              </Box>
            </Flex>
          </Card>
        </Box>

        <Flex sx={{flex: 1}}>
          <Box pr={4} sx={{flex: 1}}>
            <Flex mb={2} sx={{justifyContent: 'space-between'}}>
              <Title level={4} style={{margin: 0}}>
                Contacts
              </Title>

              {isUnstarted && customers.length > 0 && (
                <Link to={`/broadcasts/${broadcastId}/customers`}>
                  <Button>Update contacts</Button>
                </Link>
              )}
            </Flex>

            {customers && customers.length ? (
              <BroadcastCustomersTable
                customers={customers}
                onSelectPreview={this.handleUpdateIframe}
              />
            ) : (
              <Box my={4}>
                <Empty
                  image={Empty.PRESENTED_IMAGE_SIMPLE}
                  description={
                    <Text type="secondary">No contacts selected</Text>
                  }
                >
                  <Link to={`/broadcasts/${broadcastId}/customers`}>
                    <Button type="primary">Select contacts</Button>
                  </Link>
                </Empty>
              </Box>
            )}
          </Box>

          <Box sx={{flex: 1}}>
            <Flex
              mb={2}
              sx={{justifyContent: 'space-between', alignItems: 'center'}}
            >
              <Box>
                <Title level={4} style={{margin: 0}}>
                  {template?.name || 'Message template'}
                </Title>
              </Box>
              {isUnstarted &&
                (template ? (
                  <Link
                    to={`/message-templates/${template.id}?bid=${broadcastId}`}
                  >
                    <Button>Update template</Button>
                  </Link>
                ) : null)}
            </Flex>

            {template ? (
              <iframe
                title="Broadcast email template"
                style={{height: '100%', width: '100%', border: 'none'}}
                ref={(el) => (this.iframe = el)}
              />
            ) : (
              <Box my={4}>
                <Empty
                  image={Empty.PRESENTED_IMAGE_SIMPLE}
                  description={
                    <Text type="secondary">No template selected</Text>
                  }
                >
                  <Link to={`/message-templates?bid=${broadcastId}`}>
                    <Button type="primary">Select template</Button>
                  </Link>
                </Empty>
              </Box>
            )}
          </Box>
        </Flex>
      </Flex>
    );
  }
}

export default BroadcastDetailsPage;
