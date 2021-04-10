import React from 'react';
import {Link} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import {
  Button,
  Input,
  Layout,
  Menu,
  Table,
  Tag,
  Title,
  Tooltip,
} from '../common';
import {PlusOutlined} from '../icons';
import * as API from '../../api';
import * as T from '../../types';
import logger from '../../logger';
import NewTagModal from '../tags/NewTagModal';

const {Header, Sider, Content} = Layout;

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
        <Layout>
          <Sider trigger={null} collapsible collapsed={true}>
            <Menu theme="dark" mode="inline" defaultSelectedKeys={['1']}>
              <Menu.Item key="1">nav 1</Menu.Item>
              <Menu.Item key="2">nav 2</Menu.Item>
              <Menu.Item key="3">nav 3</Menu.Item>
            </Menu>
            <Content
              style={{
                margin: '24px 16px',
                padding: 24,
                minHeight: 280,
              }}
            >
              Content
            </Content>
          </Sider>
        </Layout>
        <Box my={4}></Box>
      </Box>
    );
  }
}

export default CannedConversationsOverview;
