import React from 'react';
import {Link} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import {
  Alert,
  Button,
  Input,
  Paragraph,
  Table,
  Tag,
  Text,
  Title,
  Tooltip,
} from '../common';
import {PlusOutlined} from '../icons';
import * as API from '../../api';
import * as T from '../../types';
import logger from '../../logger';
import NewTagModal from '../tags/NewTagModal';

const CannedConversationsTable = ({
  loading,
  tags,
}: {
  loading?: boolean;
  tags: Array<T.Tag>;
}) => {
  const data = tags
    .map((tag) => {
      return {key: tag.id, ...tag};
    })
    .sort((a, b) => {
      return +new Date(b.updated_at) - +new Date(a.updated_at);
    });

  const columns = [
    {
      title: 'Name',
      dataIndex: 'name',
      key: 'name',
      render: (value: string, {color}: T.Tag) => {
        return <Tag color={color}>{value}</Tag>;
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
        const {id: companyId} = record;

        return (
          <Link to={`/conversations/${companyId}`}>
            <Button>View</Button>
          </Link>
        );
      },
    },
  ];

  return <Table loading={loading} dataSource={data} columns={columns} />;
};

type Props = {};
type State = {
  filterQuery: string;
  filteredTags: Array<T.Tag>;
  isNewTagModalVisible: boolean;
  loading: boolean;
  tags: Array<T.Tag>;
};

const filterConversationsByQuery = (
  tags: Array<T.Tag>,
  query?: string
): Array<T.Tag> => {
  if (!query || !query.length) {
    return tags;
  }

  return tags.filter((tag) => {
    const {id, name, description} = tag;

    const words = [id, name, description]
      .filter((str) => str && String(str).trim().length > 0)
      .join(' ')
      .replace('_', ' ')
      .split(' ')
      .map((str) => str.toLowerCase());

    const queries = query.split(' ').map((str) => str.toLowerCase());

    return words.some((word) => {
      return queries.every((q) => word.indexOf(q) !== -1);
    });
  });
};

class CannedConversationsOverview extends React.Component<Props, State> {
  state: State = {
    filteredTags: [],
    filterQuery: '',
    isNewTagModalVisible: false,
    loading: true,
    tags: [],
  };

  async componentDidMount() {
    await this.handleRefreshTags();
  }

  handleSearchTags = (filterQuery: string) => {
    const {tags = []} = this.state;

    if (!filterQuery?.length) {
      this.setState({filterQuery: '', filteredTags: tags});
    }

    this.setState({
      filterQuery,
      filteredTags: filterConversationsByQuery(tags, filterQuery),
    });
  };

  handleRefreshTags = async () => {
    try {
      const {filterQuery} = this.state;
      const tags = await API.fetchAllTags();

      this.setState({
        filteredTags: filterConversationsByQuery(tags, filterQuery),
        loading: false,
        tags,
      });
    } catch (err) {
      logger.error('Error loading tags!', err);

      this.setState({loading: false});
    }
  };

  handleOpenNewTagModal = () => {
    this.setState({isNewTagModalVisible: true});
  };

  handleNewTagModalClosed = () => {
    this.setState({isNewTagModalVisible: false});
  };

  handleNewTagCreated = () => {
    this.handleNewTagModalClosed();
    this.handleRefreshTags();
  };

  render() {
    const {loading, isNewTagModalVisible, filteredTags = []} = this.state;

    return (
      <Box p={4} sx={{maxWidth: 1080}}>
        <Flex sx={{justifyContent: 'space-between', alignItems: 'center'}}>
          <Title level={3}>Saved Replies for Taro (beta)</Title>
          <Tooltip title="How Saved Replies Work">
            <span>This is how they work</span>
          </Tooltip>

          {/* TODO: implement me! */}
          <Button
            type="primary"
            icon={<PlusOutlined />}
            onClick={this.handleOpenNewTagModal}
          >
            New Reply
          </Button>
        </Flex>

        <NewTagModal
          visible={isNewTagModalVisible}
          onSuccess={this.handleNewTagCreated}
          onCancel={this.handleNewTagModalClosed}
        />

        <Box mb={3}>
          <Input.Search
            placeholder="Search Conversations..."
            allowClear
            onSearch={this.handleSearchTags}
            style={{width: 1000}}
          />
        </Box>

        <Box my={4}>
          <CannedConversationsTable loading={loading} tags={filteredTags} />
        </Box>
      </Box>
    );
  }
}

export default CannedConversationsOverview;
