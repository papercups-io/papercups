import React from 'react';
import {Link, RouteComponentProps} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import {
  colors,
  shadows,
  Button,
  Popconfirm,
  Result,
  Tag,
  Text,
  Title,
} from '../common';
import {ArrowLeftOutlined, DeleteOutlined} from '../icons';
import * as API from '../../api';
import * as T from '../../types';
import {sleep} from '../../utils';
import Spinner from '../Spinner';
import logger from '../../logger';
import CustomersTable from '../customers/CustomersTable';

const DetailsSectionCard = ({children}: {children: any}) => {
  return (
    <Box
      p={3}
      mb={3}
      sx={{
        bg: colors.white,
        border: '1px solid rgba(0,0,0,.06)',
        borderRadius: 4,
        boxShadow: shadows.medium,
      }}
    >
      {children}
    </Box>
  );
};

type Props = RouteComponentProps<{id: string}>;
type State = {
  loading: boolean;
  deleting: boolean;
  refreshing: boolean;
  tag: T.Tag | null;
  customers: Array<T.Customer>;
};

class TagDetailsPage extends React.Component<Props, State> {
  state: State = {
    loading: true,
    deleting: false,
    refreshing: false,
    tag: null,
    customers: [],
  };

  async componentDidMount() {
    try {
      const {id: tagId} = this.props.match.params;
      const tag = await API.fetchTagById(tagId);
      const customers = await API.fetchCustomers({tag_id: tagId});

      this.setState({tag, customers, loading: false});
    } catch (err) {
      logger.error('Error loading tag!', err);

      this.setState({loading: false});
    }
  }

  handleRefreshCustomers = async () => {
    this.setState({refreshing: true});

    try {
      const {id: tagId} = this.props.match.params;
      const customers = await API.fetchCustomers({tag_id: tagId});

      this.setState({customers, refreshing: false});
    } catch (err) {
      logger.error('Error refreshing customers!', err);

      this.setState({refreshing: false});
    }
  };

  handleDeleteTag = async () => {
    try {
      this.setState({deleting: true});
      const {id: tagId} = this.props.match.params;
      await API.deleteTag(tagId);
      await sleep(1000);

      this.props.history.push('/tags');
    } catch (err) {
      logger.error('Error deleting tag!', err);

      this.setState({deleting: false});
    }
  };

  render() {
    const {loading, deleting, refreshing, tag, customers = []} = this.state;

    if (loading) {
      return (
        <Flex
          sx={{
            flex: 1,
            justifyContent: 'center',
            alignItems: 'center',
            height: '100%',
          }}
        >
          <Spinner size={40} />
        </Flex>
      );
    } else if (!tag) {
      return <Result status="error" title="Error retrieving tag" />;
    }

    const {name, description, color} = tag;

    return (
      <Flex
        p={4}
        sx={{
          flexDirection: 'column',
          flex: 1,
          bg: 'rgb(245, 245, 245)',
        }}
      >
        <Flex
          mb={4}
          sx={{justifyContent: 'space-between', alignItems: 'center'}}
        >
          <Link to="/tags">
            <Button icon={<ArrowLeftOutlined />}>Back to all tags</Button>
          </Link>

          {/* TODO: implement me! */}
          {false && (
            <Popconfirm
              title="Are you sure you want to delete this tag?"
              okText="Yes"
              cancelText="No"
              placement="bottomLeft"
              onConfirm={this.handleDeleteTag}
            >
              <Button danger loading={deleting} icon={<DeleteOutlined />}>
                Delete tag
              </Button>
            </Popconfirm>
          )}
        </Flex>

        <Flex sx={{justifyContent: 'space-between', alignItems: 'center'}}>
          <Title level={2}>Tag details</Title>

          {/* TODO: implement me! */}
          {false && <Button>Edit tag information</Button>}
        </Flex>

        <Flex>
          <Box sx={{flex: 1, pr: 4}}>
            <DetailsSectionCard>
              <Box mb={3}>
                <Box>
                  <Text strong>Name</Text>
                </Box>

                <Text>{name}</Text>
              </Box>

              <Box mb={3}>
                <Box>
                  <Text strong>Description</Text>
                </Box>

                <Text>{description || 'N/A'}</Text>
              </Box>

              <Box mb={3}>
                <Box>
                  <Text strong>Color</Text>
                </Box>

                <Text>
                  {color ? <Tag color={color}>{color}</Tag> : <Tag>unset</Tag>}
                </Text>
              </Box>
            </DetailsSectionCard>
          </Box>

          <Box sx={{flex: 3}}>
            <DetailsSectionCard>
              <Box pb={2} sx={{borderBottom: '1px solid rgba(0,0,0,.06)'}}>
                <Title level={4}>People</Title>
              </Box>

              <CustomersTable
                loading={loading || refreshing}
                customers={customers}
                currentlyOnline={{}}
                onUpdate={this.handleRefreshCustomers}
              />
            </DetailsSectionCard>
          </Box>
        </Flex>
      </Flex>
    );
  }
}

export default TagDetailsPage;
