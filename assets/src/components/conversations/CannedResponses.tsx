import React from 'react';
import {Box, Flex} from 'theme-ui';
import {Button, Input, Layout, Menu, Title, Tooltip, colors} from '../common';
import {PlusOutlined, UserOutlined, ReadOutlined} from '../icons';
import * as API from '../../api';
import * as T from '../../types';
import logger from '../../logger';
import NewTagModal from '../tags/NewTagModal';
import {Row, Col, Space} from 'antd';

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

class CannedResponsesOverview extends React.Component<Props, State> {
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
          <Title level={3}>Saved Replies for Taro</Title>
          <Box style={{color: colors.blue[5]}}>
            <ReadOutlined style={{margin: 5, padding: 5}}></ReadOutlined>
            <Tooltip title="How Saved Replies Work">
              <span>How saved replies work</span>
            </Tooltip>
          </Box>

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
          <Sider trigger={null} collapsible>
            <Menu mode="inline" defaultSelectedKeys={['1']}>
              <Menu.Item key="1">Person A</Menu.Item>
              <Menu.Item key="2">Person B</Menu.Item>
              <Menu.Item key="3">Person C</Menu.Item>
            </Menu>
          </Sider>
          <Content
            style={{
              margin: '24px 16px',
              padding: 24,
              minHeight: 280,
            }}
          >
            <Box>
              <Row gutter={16} justify={'space-between'}>
                <Col span={4}>Name of Person</Col>
                <Col span={2} push={4}>
                  <Button>A button</Button>
                </Col>
                <Col span={2} pull={2}>
                  <Button>A Button</Button>
                </Col>
              </Row>
              <Row>
                Created by <UserOutlined></UserOutlined>Alex Reichart 8 days ago
              </Row>
            </Box>
            <Space align="center"></Space>
            <Box>This is content</Box>
          </Content>
        </Layout>
      </Box>
    );
  }
}

export default CannedResponsesOverview;
