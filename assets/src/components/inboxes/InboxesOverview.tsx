import React from 'react';
import {Link, RouteComponentProps} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import {
  colors,
  Button,
  Container,
  Paragraph,
  Table,
  Tag,
  Text,
  Title,
} from '../common';
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
      render: (value: string, record: Inbox) => {
        const isPrimary = !!record.is_primary;

        if (isPrimary) {
          return (
            <Flex sx={{alignItems: 'center'}}>
              <Text strong>{value}</Text>
              <Box ml={3}>
                <Tag color={colors.primary}>Primary</Tag>
              </Box>
            </Flex>
          );
        } else {
          return <Text strong>{value}</Text>;
        }
      },
    },
    {
      title: 'Description',
      dataIndex: 'description',
      key: 'description',
      render: (value: string) => {
        return <Text>{value || '--'}</Text>;
      },
    },
    {
      title: '',
      dataIndex: 'action',
      key: 'action',
      render: (value: string, record: Inbox) => {
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
