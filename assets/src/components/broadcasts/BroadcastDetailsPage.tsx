import React from 'react';
import {Link, RouteComponentProps} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';

import {
  Button,
  Card,
  Dropdown,
  Empty,
  Menu,
  Table,
  Text,
  Title,
} from '../common';
import * as API from '../../api';
import {Broadcast, Customer} from '../../types';
import logger from '../../logger';
import {ArrowLeftOutlined, SendOutlined, SettingOutlined} from '../icons';
import {formatBroadcastCustomers, formatDateTime} from './support';
import {formatServerError} from '../../utils';

// TODO: make it possible to select customer to preview in email template
const BroadcastCustomersTable = ({
  loading,
  customers,
  onRemoveCustomer,
  onPreviewCustomerEmail,
  onSendEmailToCustomer,
}: {
  loading?: boolean;
  customers: Array<any>;
  onRemoveCustomer: (customerId: string) => void;
  onPreviewCustomerEmail: (customerId: string) => void;
  onSendEmailToCustomer: (customerId: string) => void;
}) => {
  const data = customers.sort((a, b) => {
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
    {
      title: '',
      dataIndex: 'action',
      key: 'action',
      render: (value: string, record: any) => {
        const {customer_id: customerId} = record;

        const handleMenuClick = (data: any) => {
          switch (data.key) {
            case 'remove':
              return onRemoveCustomer(customerId);
            case 'preview':
              return onPreviewCustomerEmail(customerId);
            case 'send':
              return onSendEmailToCustomer(customerId);
            case 'profile':
            default:
              return null;
          }
        };

        return (
          <Dropdown
            overlay={
              <Menu onClick={handleMenuClick}>
                <Menu.Item key="profile">
                  <Link to={`/customers/${customerId}`}>View profile</Link>
                </Menu.Item>
                <Menu.Item key="remove">Remove from broadcast</Menu.Item>
                <Menu.Item key="preview">Preview email</Menu.Item>
                <Menu.Item key="send">Send email</Menu.Item>
              </Menu>
            }
          >
            <Button icon={<SettingOutlined />} />
          </Dropdown>
        );
      },
    },
  ];

  return <Table loading={loading} dataSource={data} columns={columns} />;
};

type Props = RouteComponentProps<{id: string}>;
type State = {
  broadcast: Broadcast | null;
  previewing: Customer | null;
  isSending: boolean;
};

export class BroadcastDetailsPage extends React.Component<Props, State> {
  iframe: any = null;

  state: State = {
    broadcast: null,
    previewing: null,
    isSending: false,
  };

  async componentDidMount() {
    await this.handleRefreshBroadcast();
  }

  handleRefreshBroadcast = async () => {
    const {id: broadcastId} = this.props.match.params;
    const broadcast = await API.fetchBroadcast(broadcastId);

    this.setState({broadcast}, () => this.handleUpdateIframe());
  };

  handleUpdateIframe = async (data?: Record<string, any>) => {
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

    if (data && Object.keys(data).length > 0) {
      const rendered = await API.renderEmailTemplate({html, data});

      doc.write(rendered);
    } else {
      doc.write(html);
    }

    doc.close();
  };

  handlePreviewCustomerEmail = async (customerId: string) => {
    const customer = await API.fetchCustomer(customerId);

    await this.handleUpdateIframe(customer);
    this.setState({previewing: customer});
  };

  handleRemoveFromBroadcast = async (customerId: string) => {
    try {
      const {id: broadcastId} = this.props.match.params;

      await API.removeCustomerFromBroadcast(broadcastId, customerId);
      await this.handleRefreshBroadcast();
    } catch (err) {
      logger.error(
        'Error removing customer from broadcast:',
        formatServerError(err)
      );
    }
  };

  handleSendToCustomer = async (customerId: string) => {
    try {
      const {id: broadcastId} = this.props.match.params;

      await API.sendBroadcastEmail(broadcastId, {customer_id: customerId});
      await this.handleRefreshBroadcast();
    } catch (err) {
      logger.error(
        'Error sending broadcast email to customer:',
        formatServerError(err)
      );
    }
  };

  handleSendBroadcast = async () => {
    try {
      this.setState({isSending: true});

      const {id: broadcastId} = this.props.match.params;
      const broadcast = await API.sendBroadcastEmail(broadcastId);

      logger.info('Sent!', broadcast);
      this.setState({broadcast});
    } catch (err) {
      logger.error('Failed to send emails!', err);
    } finally {
      this.setState({isSending: false});
    }
  };

  render() {
    const {broadcast, previewing, isSending} = this.state;

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
    const isUnfinished = state !== 'finished';
    const numCustomersSent = customers.filter((c) => !!c.sent_at).length;

    console.log('Currently previewing:', previewing);

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
          <Flex sx={{alignItems: 'center'}}>
            <Box mr={3}>
              <Link to={`/broadcasts`}>
                <Button icon={<ArrowLeftOutlined />}>Back</Button>
              </Link>
            </Box>
            <Title level={2} style={{margin: 0}}>
              {name}
            </Title>
          </Flex>
          {isUnfinished && (
            <Button
              type="primary"
              size="large"
              // TODO: disable this if the broadcast is not yet ready to send
              // disabled={true}
              icon={<SendOutlined />}
              loading={isSending}
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
                  Opened
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

              {isUnfinished && customers.length > 0 && (
                <Link to={`/broadcasts/${broadcastId}/customers`}>
                  <Button>Update contacts</Button>
                </Link>
              )}
            </Flex>

            {customers && customers.length ? (
              <BroadcastCustomersTable
                customers={customers}
                onRemoveCustomer={this.handleRemoveFromBroadcast}
                onPreviewCustomerEmail={this.handlePreviewCustomerEmail}
                onSendEmailToCustomer={this.handleSendToCustomer}
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
                  {template?.default_subject ||
                    template?.name ||
                    'Message template'}
                </Title>
              </Box>
              {isUnfinished &&
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
