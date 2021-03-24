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
} from '../common';
import {PlusOutlined} from '../icons';
import * as API from '../../api';
import * as T from '../../types';
import logger from '../../logger';
import NewTagModal from './NewTagModal';

const TagsTable = ({
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
          <Link to={`/tags/${companyId}`}>
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

const filterTagsByQuery = (
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

class TagsOverview extends React.Component<Props, State> {
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
      filteredTags: filterTagsByQuery(tags, filterQuery),
    });
  };

  handleRefreshTags = async () => {
    try {
      const {filterQuery} = this.state;
      const tags = await API.fetchAllTags();

      this.setState({
        filteredTags: filterTagsByQuery(tags, filterQuery),
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
          <Title level={3}>Tags (beta)</Title>

          {/* TODO: implement me! */}
          <Button
            type="primary"
            icon={<PlusOutlined />}
            onClick={this.handleOpenNewTagModal}
          >
            New tag
          </Button>
        </Flex>

        <NewTagModal
          visible={isNewTagModalVisible}
          onSuccess={this.handleNewTagCreated}
          onCancel={this.handleNewTagModalClosed}
        />

        <Box mb={4}>
          <Paragraph>
            Use tags to organize and manage your customers and conversations.
          </Paragraph>

          <Alert
            message={
              <Text>
                This page is still a work in progress &mdash; more features
                coming soon!
              </Text>
            }
            type="info"
            showIcon
          />
        </Box>

        <Box mb={3}>
          <Input.Search
            placeholder="Search tags..."
            allowClear
            onSearch={this.handleSearchTags}
            style={{width: 400}}
          />
        </Box>

        <Box my={4}>
          <TagsTable loading={loading} tags={filteredTags} />
        </Box>
      </Box>
    );
  }
}

export default TagsOverview;
