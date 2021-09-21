import React from 'react';
import {Link, RouteComponentProps} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import {Button, Container, Paragraph, Table, Title} from '../common';
import {PlusOutlined} from '../icons';
import * as API from '../../api';
import {Inbox} from '../../types';
import logger from '../../logger';
import {NewInboxModalButton} from './NewInboxModal';

const InboxesTable = ({
  loading,
  inboxes,
}: {
  loading?: boolean;
  inboxes: Array<Inbox>;
}) => {
  const data = inboxes
    .map((inbox) => {
      return {key: inbox.id, ...inbox};
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
        return value;
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
      title: '',
      dataIndex: 'action',
      key: 'action',
      render: (value: string, record: any) => {
        const {id: inboxId} = record;

        return (
          <Link to={`/inboxes/${inboxId}`}>
            <Button>Configure</Button>
          </Link>
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

type Props = RouteComponentProps<{}>;
type State = {
  loading: boolean;
  inboxes: Array<Inbox>;
};

class InboxesOverview extends React.Component<Props, State> {
  state: State = {
    loading: true,
    inboxes: [],
  };

  async componentDidMount() {
    await this.handleRefreshInboxs();
  }

  handleRefreshInboxs = async () => {
    try {
      const inboxes = await API.fetchInboxes();

      this.setState({
        loading: false,
        inboxes,
      });
    } catch (err) {
      logger.error('Error loading inboxes!', err);

      this.setState({loading: false});
    }
  };

  handleNewInboxCreated = (inbox: Inbox) => {
    const {id: inboxId} = inbox;

    this.props.history.push(`/inboxes/${inboxId}`);
  };

  render() {
    const {loading, inboxes = []} = this.state;

    return (
      <Container>
        <Flex sx={{justifyContent: 'space-between', alignItems: 'center'}}>
          <Title level={3}>Inboxes</Title>

          <NewInboxModalButton
            type="primary"
            icon={<PlusOutlined />}
            onSuccess={this.handleNewInboxCreated}
          >
            New inbox
          </NewInboxModalButton>
        </Flex>

        <Box mb={4}>
          <Paragraph>Create inboxes to manage your conversations.</Paragraph>
        </Box>

        <Box my={4}>
          <InboxesTable loading={loading} inboxes={inboxes} />
        </Box>
      </Container>
    );
  }
}

export default InboxesOverview;
