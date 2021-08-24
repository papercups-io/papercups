import React from 'react';
import {RouteComponentProps} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';

import {Table, Title} from '../common';
import * as API from '../../api';
import {Broadcast} from '../../types';

const formatBroadcastCustomers = (broadcast: Broadcast) => {
  const {broadcast_customers: broadcastCustomers = []} = broadcast;

  return broadcastCustomers.map((bc: any) => {
    const {customer = {}, id: key, created_at, updated_at, sent_at, state} = bc;
    const {name, email, time_zone, metadata = {}} = customer;

    return {
      key,
      created_at,
      updated_at,
      state,
      sent_at,
      name,
      email,
      time_zone,
      metadata,
    };
  });
};

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
        return value || '--';
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

  render() {
    const {broadcast} = this.state;

    if (!broadcast) {
      return null;
    }

    const {name, description} = broadcast;
    const customers = formatBroadcastCustomers(broadcast);

    return (
      <Box p={4}>
        <Title level={2}>{name}</Title>

        <Flex>
          <Box pr={4} sx={{flex: 1}}>
            <BroadcastCustomersTable
              customers={customers}
              onSelectPreview={this.handleUpdateIframe}
            />
          </Box>

          <Box sx={{flex: 1, height: 400}}>
            <iframe
              title="Broadcast email template"
              style={{height: '100%', width: '100%', border: 'none'}}
              ref={(el) => (this.iframe = el)}
            />
          </Box>
        </Flex>
      </Box>
    );
  }
}

export default BroadcastDetailsPage;
